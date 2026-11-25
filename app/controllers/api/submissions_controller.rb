class Api::SubmissionsController < Api::ApplicationController
  include Pagination
  before_action :authenticate_user!, except: [:all, :show, :toggle_published]

  def index
    if current_user.nil?
      render status: :unauthorized
      return
    end
    contest_slug = params[:contest_slug]
    contest = Contest.find_by!(slug: contest_slug)
    authorize [:api, contest], :submissions?

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
      contest.problems.pluck(:id),
      params[:options]
    )
  end

  def all
    contest_slug = params[:contest_slug]
    # @type [Contest]
    contest = Contest.find_by!(slug: contest_slug)
    page = params[:page] || 1
    count = params[:count] || 20

    contest_policy = policy([:api, contest])
    including_problem_id = contest_policy.visible_submission_problem_ids

    # 可視の問題が 1 つも無ければ 403（authorize は同じポリシーインスタンスを再利用する）
    authorize [:api, contest], :all_submissions?

    permission = contest_policy.contest_admin?

    all_submissions = Submission
                        .includes(problem: :testcase_sets)
                        .preload(:testcase_results)
                        .eager_load(:user)
                        .joins(problem: :contest)
                        .where("contests.slug = ?", contest_slug)
                        .where(problem_id: including_problem_id)
                        .where("(submissions.public OR submissions.user_id = ? OR problems.writer_user_id = ? OR ?)",
                               user_signed_in? ? current_user.id : -1,
                               user_signed_in? ? current_user.id : -1,
                               permission)
                        .page(page)
                        .per(count)

    submissions(
      all_submissions,
      contest.problems.pluck(:id),
      params[:options]
    )
  end

  def show
    # 独自のエラーメッセージを返すため authorize ではなく policy() で判定する
    skip_authorization

    #@type [Submission]
    submission = Submission.includes(testcase_results: :testcase).find(params[:id])
    contest = submission.problem.contest

    if contest.slug != params[:contest_slug]
      render status: :not_found
      return
    end

    is_admin_or_writer = policy([:api, submission.problem]).admin_or_writer?

    unless policy([:api, submission]).show?
      render_api_error('この提出は非公開です', status: :forbidden)
      return
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

    render json: submission,
           admin: is_admin_or_writer,
           serializer: SubmissionDetailSerializer,
           in_contest: in_contest,
           hide_results: r_count < t_count,
           samples: in_contest ? Set.new(samples) : nil,
           result_count: r_count,
           testcase_count: t_count,
           testcase_sets: testcase_set_results,
           permission: submission.problem.check_admin_or_writer_or_tester(current_user)
  end

  def create
    if current_user.nil?
      render status: :unauthorized
      return
    end

    problem = Problem.find_by!(slug: params[:task_slug])
    authorize [:api, problem], :submit?

    limit = check_submit_limit(problem)

    if limit.present?
      limit = limit.floor
      response.set_header('Retry-After', limit)
      render_api_error("提出制限により、#{limit} 秒後までは提出できません。", status: :too_early)
      return
    end
    _submit(problem, request.body.read)
  end

  def toggle_published
    submission = Submission.find(params[:id])
    authorize [:api, submission], :toggle_published?

    submission.public = !submission.public
    submission.save
    render json: { public: submission.public }
  end

  private

  def testcase_set_map(in_contest, testcase_results_map, testcase_set)
    min_id = 2.pow(63)
    max_id = -(2.pow(63))

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

  SORT_TABLE = {
    'date' => %w[created_at],
    'user' => %w[users.name],
    'lang' => %w[lang],
    'score' => %w[point],
    'status' => %w[status],
    'executionTime' => %w[execution_time],
    'executionMemory' => %w[execution_memory],
  }.freeze

  FILTER_TABLE = {
    'user' => 'users.name',
    'task' => 'problems.slug',
    'status' => 'status',
  }.freeze

  # @param submissions [ActiveRecord::Relation<Submission>]
  def submissions(submissions, problem_ids, options)
    if options.present?
      # 旧形式: options=<JSON> ({ sort: [{target, desc}], filter: [{target, value}] })
      options_data = JSON.parse(options)
      sort = (options_data['sort'] || []).map { |obj| [obj['target'], obj['desc'].present?] }
      filter = (options_data['filter'] || []).to_h { |obj| [obj['target'], obj['value']] }
    else
      # 新形式: sort=-date,user&user=foo&task[]=A&status[]=AC
      sort = parse_sort_param(params[:sort])
      filter = FILTER_TABLE.keys.filter_map do |target|
        value = params[target]
        # 文字列か文字列の配列のみ受け付ける
        value = value.grep(String).compact_blank if value.is_a?(Array)
        [target, value] if value.is_a?(String) || value.is_a?(Array)
      end.to_h
    end
    submissions = apply_sort(submissions, sort)
    submissions = apply_filter(submissions, filter)

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

  # "-date,user" を [["date", true], ["user", false]] に変換する
  # @return [Array<Array(String, Boolean)>]
  def parse_sort_param(sort)
    return [] unless sort.is_a?(String)

    sort.split(',').map(&:strip).compact_blank.map do |item|
      item.start_with?('-') ? [item[1..], true] : [item, false]
    end
  end

  # @param submissions [ActiveRecord::Relation<Submission>]
  # @param sort [Array<Array(String, Boolean)>] [target, desc] の配列
  def apply_sort(submissions, sort)
    sort.each do |target, desc|
      if target == 'task'
        direction = desc ? 'DESC' : 'ASC'
        submissions = submissions.order(Arel.sql("CHAR_LENGTH(problems.position) #{direction}"), Arel.sql("problems.position #{direction}"))
      elsif SORT_TABLE.key?(target)
        # 未知の target は無視する
        SORT_TABLE[target].each { |column| submissions = submissions.order(column => desc ? :desc : :asc) }
      end
    end
    submissions
  end

  # @param submissions [ActiveRecord::Relation<Submission>]
  # @param filter [Hash{String => String, Array<String>}]
  def apply_filter(submissions, filter)
    filter.each do |target, value|
      column = FILTER_TABLE[target]
      next if column.nil? || value.blank?

      submissions = submissions.where(column => value)
    end
    submissions
  end


  # @param problem [Problem]
  # @return [Integer, NilClass]
  def check_submit_limit(problem)
    if policy([:api, problem]).admin_or_writer?
      return nil
    end
    latest_submissions = Submission
                           .where(user: current_user)
                           .where.not(status: %w[IE CE])
                           .order(created_at: :desc)
                           .limit(2).to_a

    if latest_submissions.length >= 2 && problem.submission_limit_2 > 0&&
      (remain2 = Time.zone.now - latest_submissions[1].created_at - problem.submission_limit_2) < 0
      return -remain2
    end
    if latest_submissions.length >= 1 && problem.submission_limit_1 > 0 &&
        (remain1 = Time.zone.now - latest_submissions[0].created_at - problem.submission_limit_1) < 0
      return -remain1
    end

    nil
  end

  # @param [Problem] problem
  def _submit(problem, source)
    save_path = make_path

    submission = current_user.submissions.new
    submission.problem_id = problem.id
    submission.path = save_path
    submission.lang = params[:lang]
    submission.status = 'WJ'
    submission.public = !problem.check_admin_or_writer_or_tester(current_user)

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
