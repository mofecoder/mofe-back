class Api::TestcaseSetsController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_writer!

  def create
    name = params[:testcase_set][:name]
    points = params[:testcase_set][:points]
    unless @problem.testcase_sets.find_by(problem_id: params[:problem_id], name: name).nil?
      render json: { error: 'この名前のテストケースはすでに存在します。 '}, status: 400
      return
    end

    @problem.testcase_sets.create(
        name: name,
        points: points,
        is_sample: false
    )
    render status: :created
  end

  def destroy
    set = TestcaseSet.find(params[:id])
    if set.name == 'all' || set.name == 'sample'
      render json: { error: "このテストケースは削除できません。"}
    end
    set.destroy!
  end

  private

    def authenticate_writer!
      @problem = Problem.find(params[:problem_id])
      unless current_user.admin? || current_user.writer? && @problem.writer_user_id == current_user.id
        render json: {error: 'Forbidden'}, status: :forbidden
      end
    end

    def create_params
      params.required(:testcase).permit(:name, :points, :is_sample)
    end
end
