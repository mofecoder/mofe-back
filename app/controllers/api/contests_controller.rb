#noinspection RubyYardReturnMatch
class Api::ContestsController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :register, :rejudge]
  before_action :authenticate_admin_user!, only: [:create]
  before_action :set_contest, except: [:index, :create, :register, :rejudge]

  def index
    now = DateTime::now
    during = Contest.all.where('`start_at` <= ? AND `end_at` > ?', now, now).order(:end_at)
    future = Contest.all.where('`start_at` > ?', now).order(:start_at)
    past = Contest.all.where('`end_at` <= ?', now).order(end_at: :desc)
    unless current_user&.admin?
      during = during.where.not(kind: 'private')
      future = future.where.not(kind: 'private')
      past = past.where.not(kind: 'private')
    end
    render json: (during + future + past).as_json(only: [:slug, :name, :kind, :start_at, :end_at])
  end

  def show
    # @type [Contest]
    contest = Contest.includes(problems: :testcase_sets).find_by!(slug: params[:slug])
    include_flag = contest.end_at.past? ||
      (contest.start_at.past? && contest.registered?(current_user)) ||
      (user_signed_in? && current_user.admin_for_contest?(contest.id))

    writer_or_tester = []
    writer_or_tester_tasks = []
    if current_user&.admin_for_contest?(contest.id)
      writer_or_tester = contest.problems.map { |p| { id: p.id, slug: p.slug, role: 'admin' }}
    elsif contest.is_writer_or_tester(current_user)
      problems = contest.problems.includes(:tester_relations)
      problems.each do |problem|
        if current_user == problem.writer_user
          role = 'writer'
        elsif problem.tester_relations.exists?(tester_user_id: current_user.id)
          role = 'tester'
        else
          if contest.start_at.past? || contest.official_mode
            writer_or_tester_tasks.push(problem)
          end
          next
        end
        writer_or_tester.push({ id: problem.id, slug: problem.slug, role: role })
        writer_or_tester_tasks.push(problem)
      end
    end

    include_tasks = nil
    if include_flag
      include_tasks = contest.problems
    elsif writer_or_tester.present?
      include_tasks = writer_or_tester_tasks
    end

    show_editorial = contest.end_at.past? || (user_signed_in? && current_user.admin_for_contest?(contest.id))
    render json: contest, serializer: ContestDetailSerializer,
           include_tasks: include_tasks, user: current_user, show_editorial: show_editorial,
           registered: user_signed_in? && contest.registrations.exists?(user_id: current_user.id),
           written: writer_or_tester
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
    unless current_user.admin_for_contest?(@contest.id)
      render_403
      return
    end

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
    ids = params[:submission_ids]
    contest = Contest.find_by!(slug: params[:contest_slug])
    unless contest.is_writer_or_tester(current_user)
      render_403
      return
    end
    submissions = Submission.where(id: ids).includes(problem: :tester_relations)
    submissions.each do |submission|
      unless current_user.admin_for_contest?(contest.id) ||
          submission.problem.writer_user == current_user ||
          submission.problem.tester_relations.exists?(tester_user_id: current_user.id)
        render json: { error: "提出 #{submission.id} に対する権限がありません。" }, status: :forbidden
        return
      end
    end
    submissions.update_all(status: 'WR')
  end

  private
  def set_contest
    @contest = Contest.find_by!(slug: params[:slug])
  end

  # @return [ActionController::Parameters]
  def contest_update_params
    params.require(:contest).permit(
      :name, :description, :kind, :penalty_time, :start_at, :end_at, :editorial_url, :official_mode
    )
  end

  # @return [ActionController::Parameters]
  def contest_create_params
    params.require(:contest).permit(
      :name, :slug, :kind, :description, :penalty_time, :start_at, :end_at, :official_mode
    )
  end
end
