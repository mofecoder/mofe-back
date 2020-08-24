class Api::SubmitsController < ApplicationController
  before_action :authenticate_user!, except: [:all, :show]

  def index
    if current_user.nil?
      render status: :unauthorized
      return
    end
    contest_slug = params[:contest_slug]
    user_id = current_user.id
    # :contest_slugからsubmitを抽出する
    my_submits = Submit.preload(:problem, :user)
                     .joins(problem: :contest)
                     .where("contests.slug = ?", contest_slug)
                     .search_by_user_id(user_id)
                     .order(created_at: :desc)
    render json: my_submits
  end

  def all
    contest_slug = params[:contest_slug]
    # @type [Contest]
    contest = Contest.find_by!(slug: contest_slug)

    unless contest.end_at.past? || (user_signed_in? && current_user.admin?)
      render_403
      return
    end

    all_submits = Submit.preload(:problem)
                      .joins(problem: :contest)
                      .includes(:user)
                      .where("contests.slug = ?", contest_slug)
                      .order(created_at: :desc)

    render json: all_submits
  end

  def show
    submit = Submit.includes(testcase_results: :testcase).find(params[:id])
    contest = submit.problem.contest

    if contest.slug != params[:contest_slug]
      render status: :not_found
      return
    end

    is_admin_or_writer = user_signed_in? &&
        (current_user.admin? || submit.problem.writer_user_id == current_user.id)

    if !user_signed_in? || (!is_admin_or_writer && submit.user_id != current_user.id)
      unless contest.end_at.past?
        render json: {
            error: 'この提出は非公開です'
        }, status: :forbidden
        return
      end
    end

    samples = submit
                  .problem
                  .testcase_sets
                  .where(is_sample: 1)
                  .joins(:testcases)
                  .pluck(:testcase_id)

    in_contest = contest.end_at.future? && !is_admin_or_writer

    require('set')
    render json: submit,
           serializer: SubmitDetailSerializer,
           in_contest: in_contest,
           samples: in_contest ? Set.new(samples) : nil
  end

  def create
    if current_user.nil?
      render status: :unauthorized
    end

    problem = Problem.find_by!(slug: params[:task_slug])
    if problem.contest.start_at.future?
      unless user_signed_in?
        render_403
        return
      end
      unless current_user.admin? || problem.writer_user_id == current_user.id
        render_403
        return
      end
    end

    save_path = make_path

    submit = current_user.submits.new
    submit.problem_id = problem.id
    submit.path = save_path
    submit.lang = request.headers[:lang]
    submit.status = 'WJ'

    source = request.body.read
    Utils::GoogleCloudStorageClient::upload_source(save_path, source)
    submit.save!
  end

  private

  # pathを生やす
  def make_path
    "submit_sources/#{SecureRandom.uuid}"
  end
end
