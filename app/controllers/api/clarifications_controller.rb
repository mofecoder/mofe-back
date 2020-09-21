class Api::ClarificationsController < ApplicationController
  before_action :set_contest
  before_action :authenticate_user!, except: [:index]


  def index
    clarifications = @contest.clarifications.includes(:problem, :user)

    if !user_signed_in?
      problems = []
      clarifications.where!(publish: true)
    elsif current_user.admin?
      problems = @contest.problems.pluck(:id) + [nil]
    else
      problems = writer_problem_ids

      if problems.any?
        clarifications = clarifications.where(publish: true)
                             .or(clarifications.where(problem_id: problems))
                             .or(clarifications.where(user_id: current_user.id))
      else
        clarifications.where!(publish: true)
            .or(clarifications.where(user_id: current_user.id))
      end
    end

    # clarifications
    render json: clarifications, problems: problems
  end

  def show
    # @type [Clarification]
    clarification = @contest.clarifications.find(params[:id])

    if clarification.problem.present?
      is_writer_or_tester = clarification.problem.writer_user_id == current_user.id ||
          clarification.problem.tester_ids.include?(current_user.id)

      unless current_user.admin? || is_writer_or_tester
        render_403
        return
      end
    else
      unless current_user.admin?
        render_403
        return
      end
    end

    render json: clarification, problems: [clarification.problem_id]
  end

  def create
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

    # writer or tester or admin
    ok = current_user.admin?

    if clarification.problem.present?
      ok |= clarification.problem.writer_user.id == current_user.id

      unless ok
        ok |= clarification.problem.tester_ids.include?(current_user.id)
      end
    end

    unless ok
      render_403
      return
    end

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

  def writer_problem_ids
    @contest.problems.where(writer_user_id: current_user.id).pluck(:id) +
        @contest.problems.joins(:testers).where('users.id': current_user.id).pluck(:id)
  end

  def set_contest
    @contest = Contest.find_by!(slug: params[:contest_slug])
  end
end
