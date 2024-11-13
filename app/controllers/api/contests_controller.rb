#noinspection RubyYardReturnMatch
class Api::ContestsController < ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :rejudge, :set_task]
  before_action :authenticate_admin_user!, only: [:create]
  before_action :set_contest, except: [:index, :create, :rejudge]

  def index
    now = DateTime::now
    contests = Contest.all.select(:slug, :name, :kind, :start_at, :end_at)
    during = contests.where('`start_at` <= ? AND `end_at` > ?', now, now).where(permanent: false).order(:end_at)
    future = contests.where('`start_at` > ?', now).where(permanent: false).order(:start_at)
    past = contests.where('`end_at` <= ?', now).where(permanent: false).order(end_at: :desc)
    permanent = contests.where(permanent: true)
    unless current_user&.admin?
      during = during.where.not(kind: 'private')
      future = future.where.not(kind: 'private')
      past = past.where.not(kind: 'private')
      permanent = permanent.where.not(kind: 'private')
    end
    render json: { in_progress: during, future: future, past: past, permanent: permanent }
  end

  def show
    # @type [Contest]
    contest = Contest.includes(problems: :testcase_sets).find_by!(slug: params[:slug])
    include_flag = contest.end_at.past? ||
      (contest.start_at.past? && contest.registered?(current_user)) ||
      (user_signed_in? && current_user.admin_for_contest?(contest.id))

    writer_or_tester = []
    writer_or_tester_tasks = []
    is_admin = current_user&.admin_for_contest?(contest.id)
    if contest.is_writer_or_tester(current_user)
      problems = contest.problems.includes(:tester_relations)
      problems.each do |problem|
        if current_user == problem.writer_user
          role = 'writer'
        elsif is_admin
          role = 'admin'
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

    accepted = []
    if user_signed_in?
      accepted = Submission.where(user_id: current_user.id, problem: Problem.where(contest_id: contest.id))
                           .where(status: 'AC').select(:problem_id).distinct.pluck(:problem_id)
    end

    registered = nil
    if user_signed_in?
      registration = contest.registrations.find_by(user_id: current_user.id)
      team_registration = contest.team_registrations.eager_load(:team_registration_users)
                            .find_by(team_registration_users: { user_id: current_user.id })
      registered = nil
      if registration.present?
        registered = { name: nil, open: registration.open_registration }
      elsif team_registration.present?
        registered = { name: team_registration.name, open: team_registration.open_registration }
      end
    end

    render json: contest, serializer: ContestDetailSerializer,
           include_tasks: include_tasks, user: current_user, show_editorial: show_editorial,
           registered: registered, accepted: Set.new(accepted),
           written: writer_or_tester
  end

  def create
    contest = Contest.new(contest_create_params)
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

    if current_user.writer? && task.writer_user != current_user
      render json: { error: '他のユーザの問題は追加できません。' }, status: :forbidden
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
    ActiveRecord::Base.transaction do
      submissions.each do |submission|
        submission.status = 'WR'
        submission.point = nil
        submission.compile_error = nil
        submission.execution_memory = nil
        submission.execution_time = nil
        submission.testcase_results.delete_all
        submission.save
      end
    end
  end

  private
  def set_contest
    @contest = Contest.find_by!(slug: params[:slug])
  end

  # @return [ActionController::Parameters]
  def contest_update_params
    params.require(:contest).permit(
      :name, :description, :kind, :standings_mode, :penalty_time, :start_at, :end_at, :editorial_url, :official_mode,
      :allow_open_registration, :closed_password, :allow_team_registration
    )
  end

  # @return [ActionController::Parameters]
  def contest_create_params
    params.require(:contest).permit(
      :name, :slug, :kind, :standings_mode, :description, :penalty_time, :start_at, :end_at, :official_mode
    )
  end
end
