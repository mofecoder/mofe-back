#noinspection RubyYardReturnMatch
class Api::ContestsController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :register]
  before_action :authenticate_admin_user!, only: [:create, :update]
  before_action :set_contest, except: [:index, :create, :register]

  def index
    render json: Contest.all.order(start_at: :desc).as_json(only: [:slug, :name, :start_at, :end_at])
  end

  def show
    # @type [Contest]
    contest = Contest.includes(problems: :testcase_sets).find_by!(slug: params[:slug])
    include_tasks = contest.end_at.past? ||
      (contest.start_at.past? && contest.registered?(current_user)) ||
      (user_signed_in? && current_user.admin?)
    render json: contest, serializer: ContestDetailSerializer,
           include_tasks: include_tasks, user: current_user,
           registered: user_signed_in? && contest.registrations.exists?(user_id: current_user.id)
  end

  def create
    param = contest_create_params
    contest = Contest.new
    contest.slug = param[:slug]
    contest.name = param[:name]
    contest.description = param[:description]
    contest.start_at = param[:start_at]
    contest.end_at = param[:end_at]
    contest.penalty_time = param[:penalty_time]
    contest.save
    render status: :created
  end

  def update
    @contest.update!(contest_update_params)
  end

  def set_task
    unless params.has_key?(:problem_id)
      render json: { error: "パラメータ 'problem_id' が必要です。" }, status: :bad_request
      return
    end
    unless params.has_key?(:problem_slug)
      render json: { error: "パラメータ 'problem_slug' が必要です。" }, status: :bad_request
      return
    end
    unless params.has_key?(:position)
      render json: { error: "パラメータ 'position' が必要です。" }, status: :bad_request
      return
    end


    # @type [Problem]
    task = Problem.find(params[:problem_id])

    if task.contest_id.present?
      render json: { error: 'この問題はすでに他のコンテストに所属しています。' }, status: :conflict
      return
    end

    ActiveRecord::Base.transaction do
      task.contest_id = @contest.id
      task.slug = params[:problem_slug]
      task.position = params[:position]
      unless task.save
        render json: { error: task.errors }, status: :unprocessable_entity
      end
    end
  end

  def register
    contest = Contest.find_by!(slug: params[:contest_slug])
    if contest.end_at.past?
      render json: { error: 'コンテストは終了済みです。' }, status: :bad_request
      return
    end
    reg = Registration.find_or_initialize_by(user_id: current_user.id, contest_id: contest.id)
    if reg.new_record?
      if reg.save
        render status: :created
      else
        render json: { error: reg.errors }, status: :unprocessable_entity
      end
    else
      render json: { error: 'すでに参加登録されています。' }, status: :conflict
    end
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
    params.require(:contest).permit( :name, :slug, :description, :penalty_time, :start_at, :end_at)
  end
end
