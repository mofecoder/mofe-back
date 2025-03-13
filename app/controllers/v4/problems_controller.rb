class V4::ProblemsController < V4::ApplicationController
  before_action :set_problem, only: %i[show update destroy]

  def index
    authorize Problem

    problems = policy_scope(Problem).order(id: :desc)
    render json: ProblemBlueprint.render(problems, view: :problem)
  end

  def show
    authorize Problem
    render json: ProblemBlueprint.render(@problem, view: :problem_detail)
  end

  def create
    authorize Problem
    if Problem.create(problem_params.merge(writer_user: current_user))
      render json: ProblemBlueprint.render(@problem, view: :problem_detail)
    else
      render json: { errors: @problem.errors }, status: :unprocessable_content
    end
  end

  def update
    authorize @problem

    if @problem.update(problem_params)
      render json: ProblemBlueprint.render(@problem, view: :problem_detail)
    else
      render json: { errors: @problem.errors }, status: :unprocessable_content
    end
  end

  def destroy
    authorize @problem

    if @problem.contest.present?
      render json: {
        errors: ['コンテストに所属しているため削除できません。']
      }, status: :unprocessable_content
      return
    end

    if @problem.destroy
      render status: :no_content
    else
      render json: { errors: @problem.errors }, status: :unprocessable_content
    end
  end

  private

  def set_problem
    @problem = Problem.find(params[:id])
  end

  def problem_params
    params.require(:problem).permit(
      :name, :difficulty, :statement, :constraints, :partial_scores,
      :input_format, :output_format, :execution_time_limit
    )
  end
end
