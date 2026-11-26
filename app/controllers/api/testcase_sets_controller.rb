class Api::TestcaseSetsController < Api::ApplicationController
  before_action :authenticate_user!
  before_action :set_problem

  def show
    render json: @problem.testcase_sets.find(params[:id]).as_json(only: [:id, :name, :points, :is_sample, :aggregate_type])
  end

  def create
    name = params[:testcase_set][:name]
    points = params[:testcase_set][:points]
    if @problem.testcase_sets.find_by(problem_id: params[:problem_id], name: name).present?
      render_api_error('この名前のテストケースはすでに存在します。', status: :bad_request)
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
    set = @problem.testcase_sets.find(params[:id])
    param = update_params
    name = param[:name]

    if set.name != name
      if set.name == 'all' || set.name == 'sample'
        render_api_error("このテストケースは名前を変更できません。", status: :bad_request)
        return
      end

      if @problem.testcase_sets.exists?(problem_id: params[:problem_id], name: name)
        render_api_error('この名前のテストケースはすでに存在します。', status: :bad_request)
        return
      end
    end

    set.update!(param)
  end

  def destroy
    set = @problem.testcase_sets.find(params[:id])
    if set.name == 'all' || set.name == 'sample'
      render_api_error("このテストケースは削除できません。", status: :bad_request)
      return
    end
    set.discard!
  end

  private

    def set_problem
      @problem = Problem.find(params[:problem_id])
      authorize [:api, @problem], :manage_testcases?
    end

    def create_params
      params.required(:testcase_set).permit(:name, :points, :is_sample, :aggregate_type)
    end

    def update_params
      params.required(:testcase_set).permit(:name, :points, :aggregate_type)
    end
end
