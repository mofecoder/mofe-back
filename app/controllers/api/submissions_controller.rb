class Api::SubmissionsController < ApplicationController
  include Pagination
  before_action :authenticate_user!, except: [:all, :show]

  def index
    if current_user.nil?
      render status: :unauthorized
      return
    end
    contest_slug = params[:contest_slug]
    user_id = current_user.id
    page = params[:page] || 1
    count = params[:count] || 20

    submissions(
      Submission.includes(problem: :testcase_sets)
            .preload(:testcase_results)
            .eager_load(:user)
            .joins(problem: :contest)
            .where("contests.slug = ?", contest_slug)
            .search_by_user_id(user_id)
            .page(page)
            .per(count),
      Contest.find_by!(slug: contest_slug).problems.pluck(:id),
      params[:options]
    )
  end

  def all
    contest_slug = params[:contest_slug]
    # @type [Contest]
    contest = Contest.find_by!(slug: contest_slug)
    page = params[:page] || 1
    count = params[:count] || 20

    all_problem_id = contest.problems.pluck(:id)
    including_problem_id = []
    if contest.end_at.past?
      including_problem_id = all_problem_id
    elsif user_signed_in? && contest.is_writer_or_tester(current_user)
      if contest.official_mode || current_user.admin_for_contest?(contest.id)
        including_problem_id = all_problem_id
      else
        contest.problems.includes(:tester_relations).each do |problem|
          if current_user == problem.writer_user ||
              problem.tester_relations.exists?(tester_user_id: current_user.id, approved: true)
            including_problem_id.push(problem.id)
          end
        end
      end
    end

    all_submissions = Submission
                        .includes(problem: :testcase_sets)
                        .preload(:testcase_results)
                        .eager_load(:user)
                        .joins(problem: :contest)
                        .where("contests.slug = ?", contest_slug)
                        .where(problem_id: including_problem_id)
                        .page(page)
                        .per(count)

    submissions(
      all_submissions,
      contest.problems.pluck(:id),
      params[:options]
    )
  end

  def show
    #@type [Submission]
    submission = Submission.includes(testcase_results: :testcase).find(params[:id])
    contest = submission.problem.contest

    if contest.slug != params[:contest_slug]
      render status: :not_found
      return
    end

    is_admin_or_writer = user_signed_in? && (
      current_user.admin? ||
      submission.problem.writer_user_id == current_user.id ||
      submission.problem.tester_relations.where(tester_user_id: current_user.id, approved: true).exists? ||
      contest.is_writer_or_tester(current_user) && contest.official_mode
    )

    if !user_signed_in? || (!is_admin_or_writer && submission.user_id != current_user.id)
      unless contest.end_at.past?
        render json: {
            error: 'この提出は非公開です'
        }, status: :forbidden
        return
      end
    end

    samples = submission
                  .problem
                  .testcase_sets
                  .where(is_sample: 1)
                  .joins(:testcases)
                  .pluck(:testcase_id)

    in_contest = contest.end_at.future? && !is_admin_or_writer
    r_count = submission.testcase_results.count
    t_count = submission.problem.testcases
                  .where('created_at < ?', submission.updated_at)
                  .count

    testcase_results_map = submission.testcase_results.map { |x| [x.testcase_id, x] }.to_h

    testcase_sets = submission.problem.testcase_sets.eager_load(:testcases).order('testcases.name')
    # @type [TestcaseSet] testcase_set
    testcase_set_results = r_count < t_count ? nil : testcase_sets.map do |testcase_set|
      testcase_set_map(in_contest, testcase_results_map, testcase_set)
    end

    require('set')
    render json: submission,
           serializer: SubmissionDetailSerializer,
           in_contest: in_contest,
           hide_results: r_count < t_count,
           samples: in_contest ? Set.new(samples) : nil,
           result_count: r_count,
           testcase_count: t_count,
           testcase_sets: testcase_set_results
  end

  def create
    if current_user.nil?
      render status: :unauthorized
      return
    end

    problem = Problem.find_by!(slug: params[:task_slug])
    _submit(problem, request.body.read)
  end

  private

  def testcase_set_map(in_contest, testcase_results_map, testcase_set)
    min_id = 2.pow(63)
    max_id = -(2.pow(63))
    score = 0
    case testcase_set.aggregate_type
    when 'min'
      score = min_id
    when 'max'
      score = max_id
    when 'all'
      score = testcase_set.points
    else
      score = 0
    end
    res = Hash.new(0)

    testcase_set.testcases.each do |testcase|
      # @type [TestcaseResult]
      result = testcase_results_map[testcase.id]
      if result.nil?
        next
      end
      res[result.status] += 1
      case testcase_set.aggregate_type
      when 'all'
        if result.status != 'AC'
          score = 0
        end
      when 'max'
        if result.score.present? && score < result.score
          score = result.score
        end
      when 'min'
        if result.score.present? && score > result.score
          score = result.score
        end
      when 'sum'
        if result.score.present?
          score += result.score
        end
      else
        # unreachable
      end
    end

    {
      name: testcase_set.name,
      score: testcase_set.points,
      point: score,
      results: res,
      testcases: in_contest ? nil : testcase_set.testcases.map { |x| x.name },
    }
  end

  # @param submissions [ActiveRecord::Relation<Submission>]
  def submissions(submissions, problem_ids, options)
    sort_table = {
      'date' => %w[created_at],
      'user' => %w[users.name],
      'lang' => %w[lang],
      'score' => %w[point],
      'status' => %w[status],
      'executionTime' => %w[execution_time],
      'executionMemory' => %w[execution_memory],
    }
    filter_table = {
      'user' => 'users.name',
      'task' => 'problems.slug',
      'status' => 'status',
    }
    if options.present?
      options_data = JSON.parse(options)
      sort_array = options_data['sort'] || []
      sort_array.each do |obj|
        if obj['target'] == 'task'
          desc = obj['desc'] ? 'DESC' : 'ASC'
          submissions.order!("CHAR_LENGTH(problems.position) #{desc}").order!(position: desc)
        else
          sort_table[obj['target']].each { |row| submissions.order!(row => obj['desc'] ? :desc : :asc) }
        end
      end
      filter_array = options_data['filter'] || []
      filter_array.each do |obj|
        submissions.where!(filter_table[obj['target']] => obj['value'])
      end
    end

    all_testcases = get_testcases(problem_ids)
    submissions = submissions.order(created_at: :desc)
    pagination_data = pagination(submissions)

    data = submissions.map do |submission|
      # @type [Array<ActiveSupport::TimeWithZone>]
      c_testcases = all_testcases[submission.problem_id]&.map { |x| x.created_at }

      if c_testcases.nil?
        testcase_count = 0
      else
        idx = c_testcases.bsearch_index { |t| t > submission.updated_at }
        testcase_count = idx.nil? ? c_testcases.length : idx
      end

      SubmissionSerializer::new(submission, result_count: submission.testcase_results.size, testcase_count: testcase_count)
    end

    render json: { data: data, meta: pagination_data }
  end

  def _submit(problem, source)
    unless problem.has_permission?(current_user)
      render_403
    end

    save_path = make_path

    submission = current_user.submissions.new
    submission.problem_id = problem.id
    submission.path = save_path
    submission.lang = params[:lang]
    submission.status = 'WJ'

    Utils::GoogleCloudStorageClient::upload_source(save_path, source)
    submission.save!
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
