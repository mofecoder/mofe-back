#noinspection RubyYardReturnMatch
class Api::ContestsController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update]
  before_action :set_contest, except: [:index, :create]

  def index
    render json: Contest.all
                     .includes(:problems)
                     .as_json(only: [:slug, :name, :start_at, :end_at])
  end

  def show
    render json: @contest, serializer: ContestDetailSerializer
  end

  def create
    unless current_user.admin?
      render json: { error: 'Forbidden' }, status: :forbidden
      return
    end
    @contest = Contest.create(contest_update_params)

    redirect_to action: :show
  end

  def update
    unless current_user.admin?
      render json: { error: 'Forbidden' }, status: :forbidden
      return
    end
    @contest.update!(contest_update_params)

    redirect_to action: :show
  end

  def set_task
    unless params.has_key?(:problem_slug)
      render json: { error: "パラメータ 'problem_slug' が必要です。" }, status: :not_found
      return
    end

    # @type [Problem]
    task = Problem.find_by!(slug: params[:problem_slug])

    if task.contest_id.present?
      render json: { error: 'この問題はすでに他のコンテストに所属しています。' }, status: :bad_request
    end

    task.contest_id = @contest.id
  end

  private
  def set_contest
    @contest = Contest.find_by!(slug: params[:slug])
  end

  # @return [ActionController::Parameters]
  def contest_update_params
    params.require(:contest).permit(:name, :description, :penalty_time, :start_at, :end_at)
  end

  # @return [ActionController::Parameters]
  def contest_create_params
    params.require(:contest).permit(:slug, :name, :description, :penalty_time, :start_at, :end_at)
  end
end
