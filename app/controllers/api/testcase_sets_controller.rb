class Api::TestcaseSetsController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_writer!

  def show
    render json: TestcaseSet.find(params[:id]).as_json(only: [:id, :name, :points, :is_sample])
  end

  def create
    name = params[:testcase_set][:name]
    points = params[:testcase_set][:points]
    if @problem.testcase_sets.find_by(problem_id: params[:problem_id], name: name).present?
      render json: { error: 'この名前のテストケースはすでに存在します。 '}, status: :bad_request
      return
    end

    @problem.testcase_sets.create(
        name: name,
        points: points,
        is_sample: false
    )
    render status: :created
  end

  def update
    set = TestcaseSet.find(params[:id])
    param = update_params
    name = param[:name]

    if set.name != name
      if set.name == 'all' || set.name == 'sample'
        render json: { error: "このテストケースは名前を変更できません。"}, status: :bad_request
        return
      end

      if @problem.testcase_sets.exists?(problem_id: params[:problem_id], name: name)
        render json: { error: 'この名前のテストケースはすでに存在します。 '}, status: :bad_request
        return
      end
    end

    set.update!(param)
  end

  def destroy
    set = TestcaseSet.find(params[:id])
    if set.name == 'all' || set.name == 'sample'
      render json: { error: "このテストケースは削除できません。"}, status: :bad_request
      return
    end
    set.destroy!
  end

  private

    def authenticate_writer!
      @problem = Problem.find(params[:problem_id])
      unless current_user.admin_for_contest?(@problem.contest_id) ||
          current_user.writer? && @problem.writer_user_id == current_user.id
        render_403
      end
    end

    def create_params
      params.required(:testcase_set).permit(:name, :points, :is_sample)
    end

    def update_params
      params.required(:testcase_set).permit(:name, :points)
    end
end
