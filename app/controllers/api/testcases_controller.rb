require 'zip'
require 'set'
require 'fileutils'

class Api::TestcasesController < ApplicationController
  before_action :authenticate_user!

  def upload
    problem = Problem.find_by!(slug: params[:task_slug])

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

        match_input = /\Ainput\/([\w_]+)\.txt\z/.match(entry.name)
        match_output = /\Aoutput\/([\w_]+)\.txt\z/.match(entry.name)

        if match_input.present?
          inputs[match_input[1]] = entry.get_input_stream.read
        elsif match_output.present?
          outputs[match_output[1]] = entry.get_input_stream.read
        else
          puts entry.name
        end
      end
    rescue
      render json: {error: 'zipファイルの展開に失敗しました。'}, status: :unprocessable_entity
      raise
    ensure
      zip.close
    end

    # 共通するファイル名
    message = []
    common_filename = Set.new(inputs.keys + outputs.keys)
    unless ok && common_filename.any?
      render json: {error: 'zipファイルの形式が正しくありません。'}, status: :bad_request
    end

    inputs.keys.each do |k|
      message << "'input/#{k}.txt' は、output ファイルが存在しないため無視されました。" unless common_filename.include? k
    end
    outputs.keys.each do |k|
      message << "'output/#{k}.txt' は、input ファイルが存在しないため無視されました。" unless common_filename.include? k
    end

    ActiveRecord::Base.transaction do
      common_filename.each do |name|
        input = inputs[name].gsub(/\r\n|\r/, "\n")
        output = outputs[name].gsub(/\r\n|\r/, "\n")
        problem.testcases.create(name: name, input: input, output: output)
      end
    end

    FileUtils.rm_f file_path

    render json: { messages: message }
  end
end
