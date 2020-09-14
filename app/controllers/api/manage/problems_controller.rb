class Api::Manage::ProblemsController < ApplicationController
  before_action :authenticate_user!
  # GET /problems
  def unset_problems
    unless current_user.admin?
      render_403
      return
    end
    problems = Problem.includes(:writer_user).where(contest_id: nil)

    render json: problems, each_serializer: UnsetProblemSerializer
  end
end
