class Api::Manage::ProblemsController < Api::ApplicationController
  before_action :authenticate_user!

  # GET /problems
  def unset_problems
    authorize [:api, Problem], :unset_problems?

    problems = policy_scope([:api, Problem]).includes(:writer_user).where(contest_id: nil)

    render json: problems, each_serializer: UnsetProblemSerializer
  end
end
