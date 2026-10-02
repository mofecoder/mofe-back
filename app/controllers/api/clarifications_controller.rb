class Api::ClarificationsController < Api::ApplicationController
  before_action :set_contest
  before_action :authenticate_user!, except: [:index]

  def index
    authorize [:api, Clarification]

    relation = @contest.clarifications.includes(:problem, :user).order(updated_at: :desc)
    contest_policy = policy([:api, @contest])

    render json: contest_policy.visible_clarifications(relation),
           problems: contest_policy.visible_clarification_problem_ids
  end

  def show
    # @type [Clarification]
    clarification = @contest.clarifications.find(params[:id])
    authorize [:api, clarification]

    render json: clarification, problems: [clarification.problem_id]
  end

  def create
    authorize [:api, Clarification]

    clarification = @contest.clarifications.new
    clarification.question = create_params[:question]
    clarification.user_id = current_user.id

    if create_params[:task]
      clarification.problem_id = Problem.find_by!(slug: create_params[:task]).id
    end

    if clarification.save
      render json: clarification, status: :created
    else
      render json: { error: clarification.errors }, status: :unprocessable_entity
    end
  end

  def update
    clarification = Clarification.find(params[:id])
    authorize [:api, clarification]

    if clarification.update(update_params)
      render json: clarification, status: :no_content
    else
      render json: { error: clarification.errors }, status: :unprocessable_entity
    end
  end

  private

  def create_params
    params.require(:clarification).permit(:task, :question)
  end

  def update_params
    params.require(:clarification).permit(:answer, :publish)
  end

  def set_contest
    # @type [Contest]
    @contest = Contest.find_by!(slug: params[:contest_slug])
  end
end
