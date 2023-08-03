require 'zip'
require 'set'
require 'fileutils'

class Api::TestcasesController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_writer!

  def index
    # @type [Array<TestcaseSet>]
    testcase_sets = @problem.testcase_sets.order(is_sample: :desc, name: :asc).to_a
    # @type [Array<Testcase>]
    testcases = @problem.testcases.order(:name).includes(:testcase_sets).to_a

    # @type [Hash<Hash>]
    tmp = {}

    testcases.each do |testcase|
      set = Set.new(testcase.testcase_sets.map(&:id))
      tmp[testcase.id] = []
      testcase_sets.each do |ts|
        tmp[testcase.id] << set.include?(ts.id)
      end
    end

    res = []
    indexed = testcases.index_by(&:id)

    tmp.each do |id, set|
      res << {
          id: id,
          name: indexed[id].name,
          testcase_sets: set
      }
    end

    testcase_sets.map! do |set|
      {
          id: set.id,
          name: set.name,
          is_sample: set.is_sample,
          points: set.points
      }
    end
    render json: {
        testcase_sets: testcase_sets,
        testcases: res
    }
  end

  def show
    render json: @problem.testcases.find(params[:id])
  end

  def create
    unless @problem.testcases.find_by(name: create_params[:name]).nil?
      render json: { error: 'この名前のテストケースはすでに存在します。 '}, status: 400
      return
    end
    testcase = @problem.testcases.new(create_params)
    testcase.input_data = params[:testcase][:input]
    testcase.output_data = params[:testcase][:output]
    testcase.save!
    set = TestcaseSet.find_by(problem_id: @problem.id, name: 'all')
    TestcaseTestcaseSet.create(testcase_id: testcase.id, testcase_set_id: set.id)
    render status: :created
  end

  def destroy
    # @type [Testcase]
    testcase = @problem.testcases.find(params[:id])
    testcase.destroy!
  end

  def update
    # @type [Testcase]
    testcase = @problem.testcases.find(params[:id])
    testcase.update(create_params)
    input = params[:testcase][:input]
    output = params[:testcase][:output]
    if testcase.input || testcase.output
      testcase.input = input
      testcase.output = output
    end
    testcase.input_data = input
    testcase.output_data = output
    testcase.save!
  end

  def upload
    file_path = "./tmp/#{SecureRandom.uuid}.zip"
    # @type [ActionDispatch::Http::UploadedFile]
    file = params[:file]
    File.open(file_path, 'wb') do |f|
      f.write file.read
    end

    ok = true
    zip = Zip::File.open(file_path)
    begin
      inputs, outputs = {}, {}
      if zip.entries.length == 0
        ok = false
      end

      # @type [Zip::Entry] entry
      zip.each do |entry|
        next unless entry.ftype == :'file'

        match_input = /\Ainput\/([\w_-]+)\.txt\z/.match(entry.name)
        match_output = /\Aoutput\/([\w_-]+)\.txt\z/.match(entry.name)
        if match_input.present?
          inputs[match_input[1].gsub(/-/, '_')] = entry.get_input_stream.read
        elsif match_output.present?
          outputs[match_output[1].gsub(/-/, '_')] = entry.get_input_stream.read
        end
      end
    rescue
      render json: {error: 'zipファイルの展開に失敗しました。'}, status: :unprocessable_entity
      return
    ensure
      zip.close
    end

    # 共通するファイル名
    message = []
    common_filename = Set.new(inputs.keys & outputs.keys)
    unless ok && common_filename.any?
      render json: {error: 'zipファイルの形式が正しくありません。'}, status: :bad_request
      return
    end

    inputs.keys.each do |k|
      message << "'input/#{k}.txt' は、output ファイルが存在しないため無視されました。" unless common_filename.include? k
    end
    outputs.keys.each do |k|
      message << "'output/#{k}.txt' は、input ファイルが存在しないため無視されました。" unless common_filename.include? k
    end

    existing_testcase_names = Set.new @problem.testcases.pluck(:name)
    all_testcase_set = @problem.testcase_sets.find_by!(name: 'all')

    ActiveRecord::Base.transaction do
      common_filename.each do |name|
        if existing_testcase_names.include?(name)
          if params.has_key?('overwrite')
            @problem.testcases.where(name: name).destroy!
          else
            message << "'#{name}.txt' は、同名のテストケースが既に存在するため無視されました。"
            next
          end
        end

        input = inputs[name].gsub(/\r\n|\r/, "\n")
        output = outputs[name].gsub(/\r\n|\r/, "\n")
        # @type [Testcase]
        testcase = @problem.testcases.create(name: name)
        testcase.input_data = input
        testcase.output_data = output
        testcase.testcase_testcase_sets.create(testcase_set_id: all_testcase_set.id)
      end
    end

    FileUtils.rm_f file_path

    render json: {messages: message}
  end

  def change_state
    # @type [Testcase]
    testcase = @problem.testcases.find(params[:id])
    testcase_set_id = params[:testcase_set_id]
    @problem.testcase_sets.find(testcase_set_id)
    s = TestcaseTestcaseSet.find_by(testcase_id: testcase.id, testcase_set_id: testcase_set_id)

    if params[:state]
      return if s.present?
      testcase.testcase_testcase_sets.create(
          testcase_set_id: testcase_set_id
      )
    else
      return if s.nil?
      s.really_destroy!
    end
  end

  private

  def authenticate_writer!
    @problem = Problem.find(params[:problem_id])
    unless current_user.admin_for_contest?(@problem.contest_id) || current_user.writer? && @problem.writer_user_id == current_user.id
      render_403
    end
  end

  def create_params
    params.required(:testcase).permit(:name, :explanation)
  end
end
