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
    my_submits = Submit.includes(problem: :testcase_sets)
                     .includes(:user)
                     .joins(problem: :contest)
                     .where("contests.slug = ?", contest_slug)
                     .search_by_user_id(user_id)

    # problemId -> testcase.created_at
    all_testcases = get_testcases(problem_ids)

    testcase_count = {}
    my_submits.each do |submit|
      # submit.updated_at > testcase.created_at
      submit_updated_at = submit.updated_at

      # @type [Array<ActiveSupport::TimeWithZone>]
      c_testcases = all_testcases[submit.problem_id]&.map { |x| x.created_at }

      if c_testcases.nil?
        testcase_count[submit.id] = 0
      else
        idx = c_testcases.bsearch_index { |t| t > submit_updated_at }

        testcase_count[submit.id] = idx.nil? ? c_testcases.length : idx
      end
    end

    submit_ids = my_submits.pluck(:id)
    result_counts = TestcaseResult.where(submit_id: submit_ids).group(:submit_id).count

    render json: my_submits.order(created_at: :desc), result_counts: result_counts, testcase_count: testcase_count
  end

  def all
    contest_slug = params[:contest_slug]
    # @type [Contest]
    contest = Contest.find_by!(slug: contest_slug)

    unless contest.end_at.past?
      unless user_signed_in? && contest.is_writer_or_tester(current_user)
        render_403
        return
      end
    end

    problem_ids = contest.problems.pluck(:id)
    all_submits = Submit.includes(problem: :testcase_sets)
                      .includes(:user)
                      .joins(problem: :contest)
                      .where("contests.slug = ?", contest_slug)

    # problemId -> testcase.created_at
    all_testcases = get_testcases(problem_ids)

    testcase_count = {}
    all_submits.each do |submit|
      # submit.updated_at > testcase.created_at
      submit_updated_at = submit.updated_at

      # @type [Array<ActiveSupport::TimeWithZone>]
      c_testcases = all_testcases[submit.problem_id]&.map { |x| x.created_at }

      if c_testcases.nil?
        testcase_count[submit.id] = 0
      else
        idx = c_testcases.bsearch_index { |t| t > submit_updated_at }

        testcase_count[submit.id] = idx.nil? ? c_testcases.length : idx
      end
    end

    submit_ids = all_submits.pluck(:id)
    result_counts = TestcaseResult.where(submit_id: submit_ids).group(:submit_id).count

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
    r_count = submit.testcase_results.count
    t_count = submit.problem.testcases
                  .where('created_at < ?', submit.updated_at)
                  .count
    result_counts = {}
    result_counts[submit.id] = r_count
    testcase_count = {}
    testcase_count[submit.id] = t_count

    require('set')
    render json: submit,
           serializer: SubmitDetailSerializer,
           in_contest: in_contest,
           hide_results: r_count < t_count,
           samples: in_contest ? Set.new(samples) : nil,
           result_counts: result_counts,
           testcase_count: testcase_count
  end

  def create
    if current_user.nil?
      render status: :unauthorized
    end

    problem = Problem.find_by!(slug: params[:task_slug])
    _submit(problem, request.body.read)
  end

  private

  def _submit(problem, source)
    if problem.contest.start_at.future?
      unless user_signed_in?
        render_403
        return
      end
      if !current_user.admin? &&
          problem.writer_user_id != current_user.id &&
          problem.tester_relations.where(tester_user_id: current_user.id, approved: true).empty?
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

    Utils::GoogleCloudStorageClient::upload_source(save_path, source)
    submit.save!
  end

  def get_testcases(problem_ids)
    Testcase.where(problem_id: problem_ids)
        .select(:problem_id, :created_at)
        .order(:created_at)
        .to_a
        .group_by { |t| t.problem_id }
  end

  # pathを生やす
  def make_path
    "submit_sources/#{SecureRandom.uuid}"
  end
end
