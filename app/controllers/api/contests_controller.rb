#noinspection RubyYardReturnMatch
class Api::ContestsController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update]
  before_action :authenticate_admin_user!, only: [:create, :update]
  before_action :set_contest, except: [:index, :create]

  def index
    render json: Contest.all.order(start_at: :desc).as_json(only: [:slug, :name, :start_at, :end_at])
  end

  def show
    contest = Contest.includes(problems: :testcase_sets).find_by!(slug: params[:slug])
    render json: contest, serializer: ContestDetailSerializer
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
