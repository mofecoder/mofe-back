class Api::SubmitsController < ApplicationController
  before_action :authenticate_user!, except: [:all, :show]

  def index
    if current_user.nil?
      render status: :unauthorized
      return
    end
    contest_slug = params[:contest_slug]
    user_id = current_user.id

    problem_ids = Contest.find_by!(slug: contest_slug).problems.pluck(:id)

    # :contest_slugからsubmitを抽出する
    my_submits = Submit.includes(:problem, :user)
                     .joins(problem: :contest)
                     .where("contests.slug = ?", contest_slug)
                     .search_by_user_id(user_id)

    submit_ids = my_submits.pluck(:id)
    result_counts = TestcaseResult.where(submit_id: submit_ids).group(:submit_id).count
    testcase_count = Testcase.where(problem_id: problem_ids).group(:problem_id).count

    render json: my_submits.order(created_at: :desc), result_counts: result_counts, testcase_count: testcase_count
  end

  def all
    contest_slug = params[:contest_slug]
    # @type [Contest]
    contest = Contest.find_by!(slug: contest_slug)

    unless contest.end_at.past? || (user_signed_in? && current_user.admin?)
      render_403
      return
    end

    problem_ids = contest.problems.pluck(:id)
    all_submits = Submit.includes(:problem, :user)
                      .joins(problem: :contest)
                      .where("contests.slug = ?", contest_slug)

    submit_ids = all_submits.pluck(:id)
    result_counts = TestcaseResult.where(submit_id: submit_ids).group(:submit_id).count
    testcase_count = Testcase.where(problem_id: problem_ids).group(:problem_id).count

    render json: all_submits.order(created_at: :desc), result_counts: result_counts, testcase_count: testcase_count
  end

  def show
    #@type [Submit]
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
    result_counts = {}
    result_counts[submit.id] = submit.testcase_results.count
    testcase_count = {}
    testcase_count[submit.problem.id] = submit.problem.testcases.count

    require('set')
    render json: submit,
           serializer: SubmitDetailSerializer,
           in_contest: in_contest,
           samples: in_contest ? Set.new(samples) : nil,
           result_counts: result_counts,
           testcase_count: testcase_count
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
