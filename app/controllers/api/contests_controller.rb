#noinspection RubyYardReturnMatch
class Api::ContestsController < Api::ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :rejudge, :set_task]
  before_action :set_contest, except: [:index, :create, :rejudge]

  def index
    authorize [:api, Contest]

    now = DateTime::now
    contests = policy_scope([:api, Contest]).select(:slug, :name, :kind, :start_at, :end_at)
    during = contests.where('`start_at` <= ? AND `end_at` > ?', now, now).where(permanent: false).order(:end_at)
    future = contests.where('`start_at` > ?', now).where(permanent: false).order(:start_at)
    past = contests.where('`end_at` <= ?', now).where(permanent: false).order(end_at: :desc)
    permanent = contests.where(permanent: true)
    render json: { in_progress: during, future: future, past: past, permanent: permanent }
  end

  def show
    # @type [Contest]
    contest = Contest.includes(problems: :testcase_sets).find_by!(slug: params[:slug])
    authorize [:api, contest]

    contest_policy = policy([:api, contest])
    include_flag = contest_policy.include_tasks?

    writer_or_tester = []
    writer_or_tester_tasks = []
    is_admin = contest_policy.contest_admin?
    if contest.writer_or_tester?(current_user)
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

    show_editorial = contest_policy.show_editorial?

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
    authorize [:api, Contest]

    contest = Contest.new(contest_create_params)
    contest.save
    render status: :created
  end

  def update
    authorize [:api, @contest]

    @contest.update!(contest_update_params)
  end

  def set_task
    authorize [:api, @contest], :set_task?

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

    unless policy([:api, task]).add_to_contest?
      render json: { error: '他のユーザの問題は追加できません。' }, status: :forbidden
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

  def rejudge
    ids = params[:submission_ids]
    contest = Contest.find_by!(slug: params[:contest_slug])
    authorize [:api, contest], :rejudge?

    submissions = Submission.where(id: ids).includes(problem: :tester_relations).to_a
    if submissions.any? { |submission| submission.problem.contest_id != contest.id }
      render json: { error: 'このコンテストの提出ではないものが含まれています。' }, status: :forbidden
      return
    end

    # コンテスト管理者は全提出を再ジャッジできる。それ以外は提出ごとに問題の writer / 承認済み tester かを見る
    unless contest.admin?(current_user)
      denied = submissions.find { |submission| !policy([:api, submission]).rejudge_as_problem_member? }
      if denied
        render json: { error: "提出 #{denied.id} に対する権限がありません。" }, status: :forbidden
        return
      end
    end

    submission_ids = submissions.map(&:id)
    ActiveRecord::Base.transaction do
      TestcaseResult.where(submission_id: submission_ids).delete_all
      Submission.where(id: submission_ids).update_all(
        status: 'WR', point: nil, compile_error: nil, execution_memory: nil, execution_time: nil,
        updated_at: Time.current
      )
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
