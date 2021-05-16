#noinspection RubyYardReturnMatch
class Api::ContestsController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :register, :rejudge]
  before_action :authenticate_admin_user!, only: [:create, :update]
  before_action :set_contest, except: [:index, :create, :register, :rejudge]

  def index
    now = DateTime::now
    during = Contest.all.where('`start_at` <= ? AND `end_at` > ?', now, now).order(:end_at)
    future = Contest.all.where('`start_at` > ?', now).order(:start_at)
    past = Contest.all.where('`end_at` <= ?', now).order(end_at: :desc)
    render json: (during + future + past).as_json(only: [:slug, :name, :start_at, :end_at])
  end

  def show
    # @type [Contest]
    contest = Contest.includes(problems: :testcase_sets).find_by!(slug: params[:slug])
    include_flag = contest.end_at.past? ||
      (contest.start_at.past? && contest.registered?(current_user)) ||
      (user_signed_in? && current_user.admin?)

    writer_or_tester = []
    if contest.is_writer_or_tester(current_user)
      problems = contest.problems.includes(:tester_relations)
      problems.each do |problem|
        if current_user == problem.writer_user || problem.tester_relations.exists?(tester_user_id: current_user.id)
          writer_or_tester.push(problem)
        end
      end
    end

    include_tasks = nil
    if include_flag
      include_tasks = contest.problems
    elsif writer_or_tester.present?
      include_tasks = writer_or_tester
    end

    show_editorial = contest.end_at.past? || (user_signed_in? && current_user.admin?)
    render json: contest, serializer: ContestDetailSerializer,
           include_tasks: include_tasks, user: current_user, show_editorial: show_editorial,
           registered: user_signed_in? && contest.registrations.exists?(user_id: current_user.id),
           written: writer_or_tester.map(&:slug)
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

  def rejudge
    ids = params[:submit_ids]
    contest = Contest.find_by!(slug: params[:contest_slug])
    unless contest.is_writer_or_tester(current_user)
      render_403
      return
    end
    submits = Submit.where(id: ids).includes(problem: :tester_relations)
    submits.each do |submit|
      unless current_user.admin? ||
          submit.problem.writer_user == current_user ||
          submit.problem.tester_relations.exists?(tester_user_id: current_user.id)
        render json: { error: "提出 #{submit.id} に対する権限がありません。" }, status: :forbidden
        return
      end
    end
    submits.update_all(status: 'WR')
  end

  private
  def set_contest
    @contest = Contest.find_by!(slug: params[:slug])
  end

  # @return [ActionController::Parameters]
  def contest_update_params
    params.require(:contest).permit(:name, :description, :penalty_time, :start_at, :end_at, :editorial_url)
  end

  # @return [ActionController::Parameters]
  def contest_create_params
    params.require(:contest).permit( :name, :slug, :description, :penalty_time, :start_at, :end_at)
  end
end
