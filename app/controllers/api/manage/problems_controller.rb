class Api::Manage::ProblemsController < ApplicationController
  before_action :authenticate_user!
  # GET /problems
  def unset_problems
    if current_user.role == 'member'
      render_403
      return
    end
    problems = Problem.includes(:writer_user).where(contest_id: nil)
    if current_user.writer?
      problems.where!(writer_user: current_user)
    end

    render json: problems, each_serializer: UnsetProblemSerializer
  end
end
