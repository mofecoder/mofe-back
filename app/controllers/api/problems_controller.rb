class Api::ProblemsController < ApplicationController
  before_action :set_problem, only: [:show, :update]
  before_action :authenticate_user!
  before_action :authenticate_writer!

  # GET /problems
  def index
    unless current_user.admin?
      render json: {error: 'Forbidden'}, status: :forbidden
      return
    end
    problems = Problem.where(contest_id: nil)
    problems.where!(writer_user_id: current_user.id) unless current_user.admin?

    render json: problems
  end

  # GET /problems/1
  def show
    unless current_user.admin? || @problem.writer_user_id == current_user.id
      render json: {error: 'Forbidden'}, status: :forbidden
      return
    end
    if @problem.contest_id.present?
      render json: { error: 'この問題は既にコンテストに所属しています。'}, status: :conflict,
             location: "/api/contests/#{@problem.contest.slug}/tasks/#{@problem.slug}"
      return
    end
    render json: @problem, serializer: ProblemDetailSerializer
  end

  # POST /problems
  def create
    @problem = Problem.new(problem_params)
    @problem.writer_user_id = current_user.id

    if @problem.save
      render serializer: ProblemDetailSerializer, status: :created
    else
      render json: @problem.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /problems/1
  def update
    unless current_user.admin? || @problem.writer_user_id == current_user.id
      render json: {error: 'Forbidden'}, status: :forbidden
      return
    end
    if @problem.update(problem_params)
      render serializer: ProblemDetailSerializer
    else
      render json: @problem.errors, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_problem
    @problem = Problem.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def problem_params
    params.require(:problem).permit(:name, :difficulty, :statement, :constraints, :input_format, :output_format)
  end

  def authenticate_writer!
    unless current_user.admin? || current_user.writer?
      render json: {error: 'Forbidden'}, status: :forbidden
    end
  end
end
