# frozen_string_literal: true

require 'test_helper'

# NOTE: create の成功パスは Google Cloud Storage へソースをアップロードするためテストしない。
# 権限エラーで早期リターンする経路は GCS に到達しないので検証できる。
class Api::SubmissionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @contest = contests(:active_contest)
    @ended_contest = contests(:ended_contest)
    @problem = problems(:writer_problem)
    @member_submission = submissions(:member_submission)
    @writer_submission = submissions(:writer_submission)
  end

  # --- index ---

  test "index returns 401 when not authenticated" do
    get api_contest_submissions_url(contest_slug: @contest.slug)
    assert_response :unauthorized
  end

  test "index returns only the current user's submissions" do
    sign_in_as @member
    get api_contest_submissions_url(contest_slug: @contest.slug)
    assert_response :success

    ids = JSON.parse(response.body)['data'].map { |s| s['id'] }
    assert_includes ids, @member_submission.id
    assert_not_includes ids, @writer_submission.id
  end

  test "index returns pagination metadata" do
    sign_in_as @member
    get api_contest_submissions_url(contest_slug: @contest.slug)
    assert_response :success

    pagination = JSON.parse(response.body).dig('meta', 'pagination')
    assert_equal 1, pagination['current']
    assert_nil pagination['previous']
    assert_equal 1, pagination['count']
    assert_equal 1, pagination['pages']
  end

  test "index returns 404 for an unknown contest" do
    sign_in_as @member
    get api_contest_submissions_url(contest_slug: 'no-such-contest')
    assert_response :not_found
  end

  # --- all ---

  test "all returns 403 for anonymous users while the contest is running" do
    get all_api_contest_submissions_url(contest_slug: @contest.slug)
    assert_response :forbidden
  end

  test "all returns 200 for anonymous users once the contest has ended" do
    get all_api_contest_submissions_url(contest_slug: @ended_contest.slug)
    assert_response :success
    assert_kind_of Array, JSON.parse(response.body)['data']
  end

  test "all returns 403 for a member while the contest is running" do
    sign_in_as @member
    get all_api_contest_submissions_url(contest_slug: @contest.slug)
    assert_response :forbidden
  end

  test "all returns the submissions of the problem writer" do
    sign_in_as @writer
    get all_api_contest_submissions_url(contest_slug: @contest.slug)
    assert_response :success

    ids = JSON.parse(response.body)['data'].map { |s| s['id'] }
    assert_includes ids, @writer_submission.id
  end

  test "all returns every submission for an admin" do
    sign_in_as @admin
    get all_api_contest_submissions_url(contest_slug: @contest.slug)
    assert_response :success

    ids = JSON.parse(response.body)['data'].map { |s| s['id'] }
    assert_includes ids, @member_submission.id
    assert_includes ids, @writer_submission.id
  end

  # --- all: 絞り込み・ソート ---

  def all_submission_ids(params)
    sign_in_as @admin
    get all_api_contest_submissions_url(contest_slug: @contest.slug), params: params
    assert_response :success
    JSON.parse(response.body)['data'].map { |s| s['id'] }
  end

  test "all sorts by the new sort param in descending order" do
    assert_equal [@member_submission.id, @writer_submission.id], all_submission_ids(sort: '-score')
  end

  test "all sorts by the new sort param in ascending order" do
    assert_equal [@writer_submission.id, @member_submission.id], all_submission_ids(sort: 'score')
  end

  test "all accepts multiple sort keys including task" do
    assert_equal [@writer_submission.id, @member_submission.id], all_submission_ids(sort: 'task,-executionTime')
  end

  test "all ignores unknown sort targets" do
    ids = all_submission_ids(sort: '-unknown,score')
    assert_equal [@writer_submission.id, @member_submission.id], ids
  end

  test "all filters by status with the new format" do
    assert_equal [@member_submission.id], all_submission_ids(status: ['AC'])
  end

  test "all filters by user name with the new format" do
    assert_equal [@writer_submission.id], all_submission_ids(user: @writer.name)
  end

  test "all filters by task slug with the new format" do
    assert_equal 2, all_submission_ids(task: [@problem.slug]).length
    assert_empty all_submission_ids(task: ['no-such-problem'])
  end

  test "all still accepts the legacy options param" do
    options = {
      sort: [{ target: 'score', desc: false }],
      filter: [{ target: 'status', value: %w[AC WA] }]
    }.to_json
    assert_equal [@writer_submission.id, @member_submission.id], all_submission_ids(options: options)
  end

  test "all ignores unknown sort targets in the legacy options param" do
    options = { sort: [{ target: 'unknown', desc: true }] }.to_json
    assert_equal 2, all_submission_ids(options: options).length
  end

  # --- show ---
  #
  # 成功パスは SubmissionDetailSerializer#source が Google Cloud Storage を参照するため
  # テストしない。権限チェックで早期リターンするケースのみを検証する。

  test "show returns 403 for anonymous users while the contest is running" do
    get api_contest_submission_url(contest_slug: @contest.slug, id: @member_submission.id)
    assert_response :forbidden
  end

  test "show returns 403 for a member looking at another user's private submission" do
    sign_in_as @member
    get api_contest_submission_url(contest_slug: @contest.slug, id: @writer_submission.id)
    assert_response :forbidden
  end

  test "show returns 404 when the contest slug does not match the submission" do
    get api_contest_submission_url(contest_slug: @ended_contest.slug, id: @member_submission.id)
    assert_response :not_found
  end

  test "show returns 404 for an unknown submission" do
    get api_contest_submission_url(contest_slug: @contest.slug, id: 0)
    assert_response :not_found
  end

  # 開催中のコンテストでも、他人が書いた問題の contest_admin にはテストケース評価情報が見える
  test "show returns testcase results, names and score to a writer-role contest admin during the contest" do
    contest_admin = users(:writer_user)
    problem = problems(:admin_problem)
    problem.update_columns(contest_id: @contest.id)
    submission = Submission.create!(
      user: @member, problem: problem, path: '/submissions/ca',
      status: 'AC', point: 100, lang: 'cpp', public: false
    )
    submission.update_columns(updated_at: 1.minute.from_now)
    TestcaseResult.create!(
      submission: submission, testcase: testcases(:two),
      status: 'AC', score: 100, execution_time: 10, execution_memory: 10
    )
    ContestAdmin.create!(user: contest_admin, contest: @contest)
    assert_not_equal contest_admin.id, problem.writer_user_id

    sign_in_as contest_admin
    # source は GCS から取得されるのでスタブする
    client = Utils::GoogleCloudStorageClient
    original = client.method(:get_source)
    client.define_singleton_method(:get_source) { |_path| StringIO.new('int main(){}') }
    begin
      get api_contest_submission_url(contest_slug: @contest.slug, id: submission.id)
    ensure
      client.define_singleton_method(:get_source, original)
    end
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 1, body['testcase_results'].length
    assert_equal 'testcase_2', body['testcase_results'][0]['testcase_name']
    assert_equal 100, body['testcase_results'][0]['score']
    assert_equal ['testcase_2'], body['testcase_sets'][0]['testcases']
  end

  # --- toggle_published ---

  test "toggle_published returns 403 when not authenticated" do
    patch toggle_published_api_contest_submission_url(contest_slug: @contest.slug, id: @member_submission.id)
    assert_response :forbidden
  end

  test "toggle_published returns 403 for a member" do
    sign_in_as @member
    patch toggle_published_api_contest_submission_url(contest_slug: @contest.slug, id: @member_submission.id)
    assert_response :forbidden
  end

  test "toggle_published flips the flag for the problem writer" do
    sign_in_as @writer
    patch toggle_published_api_contest_submission_url(contest_slug: @contest.slug, id: @member_submission.id)
    assert_response :success

    assert_equal false, JSON.parse(response.body)['public']
    assert_equal false, @member_submission.reload.public
  end

  test "toggle_published flips the flag for an admin" do
    sign_in_as @admin
    patch toggle_published_api_contest_submission_url(contest_slug: @contest.slug, id: @writer_submission.id)
    assert_response :success

    assert_equal true, JSON.parse(response.body)['public']
    assert_equal true, @writer_submission.reload.public
  end

  # --- create ---

  test "create returns 401 when not authenticated" do
    post api_contest_task_submit_url(contest_slug: @contest.slug, task_slug: @problem.slug),
         params: { lang: 'cpp23' }
    assert_response :unauthorized
  end

  test "create returns 403 and creates no submission for an unauthorized user" do
    # member_user は直前の提出があり check_submit_limit で 425 になるため、
    # 提出履歴の無いユーザを作って権限チェックだけを検証する
    user = User.create!(
      name: 'nosubmit', email: 'nosubmit@example.com',
      password: 'password', password_confirmation: 'password',
      provider: 'email', uid: 'nosubmit@example.com', role: 'member'
    )
    # 開催中のコンテストに未登録なので Problem#has_permission? が false になる
    assert_not @problem.has_permission?(user)

    sign_in_as user
    assert_no_difference -> { Submission.count } do
      post api_contest_task_submit_url(contest_slug: @contest.slug, task_slug: @problem.slug),
           params: { lang: 'cpp23' }
    end
    assert_response :forbidden
  end

  def create_user(name)
    User.create!(
      name: name, email: "#{name}@example.com",
      password: 'password', password_confirmation: 'password',
      provider: 'email', uid: "#{name}@example.com", role: 'member'
    )
  end

  def create_team(contest, *users)
    team = TeamRegistration.create!(contest: contest, name: "team_#{SecureRandom.hex(3)}", passphrase: 'pass')
    users.each { |u| team.team_registration_users.create!(user: u) }
    team
  end

  def create_submission(user, problem, public: false)
    Submission.create!(
      user: user, problem: problem, path: '/submissions/x',
      status: 'AC', point: 100, lang: 'cpp', public: public
    )
  end

  # --- team ---

  test "team returns 401 when not authenticated" do
    get team_api_contest_submissions_url(contest_slug: @contest.slug)
    assert_response :unauthorized
  end

  test "team returns 403 when the user is not in a team" do
    sign_in_as @member
    get team_api_contest_submissions_url(contest_slug: @contest.slug)
    assert_response :forbidden
  end

  test "team returns submissions of all teammates only" do
    mate = create_user('mate')
    outsider = create_user('outsider')
    other_mate = create_user('other_mate')
    create_team(@contest, @member, mate)
    create_team(@contest, outsider, other_mate)
    mate_sub = create_submission(mate, @problem)
    outsider_sub = create_submission(outsider, @problem)
    other_contest_sub = create_submission(mate, problems(:admin_problem))

    sign_in_as @member
    get team_api_contest_submissions_url(contest_slug: @contest.slug)
    assert_response :success

    data = JSON.parse(response.body)['data']
    ids = data.map { |s| s['id'] }
    assert_includes ids, @member_submission.id
    assert_includes ids, mate_sub.id
    assert_not_includes ids, outsider_sub.id
    assert_not_includes ids, other_contest_sub.id
    assert_not_includes ids, @writer_submission.id
    assert_includes data.map { |s| s.dig('user', 'name') }, 'mate'
  end

  test "team paginates" do
    mate = create_user('mate')
    create_team(@contest, @member, mate)
    create_submission(mate, @problem)

    sign_in_as @member
    get team_api_contest_submissions_url(contest_slug: @contest.slug), params: { count: 1, page: 2 }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 1, body['data'].length
    pagination = body.dig('meta', 'pagination')
    assert_equal 2, pagination['current']
    assert_equal 2, pagination['pages']
  end

  test "team accepts the sort and filter query params" do
    mate = create_user('mate')
    create_team(@contest, @member, mate)
    create_submission(mate, @problem)

    sign_in_as @member
    get team_api_contest_submissions_url(contest_slug: @contest.slug), params: { user: 'mate', sort: '-date' }
    assert_response :success

    names = JSON.parse(response.body)['data'].map { |s| s.dig('user', 'name') }
    assert_equal ['mate'], names
  end

  # --- show (teammate) ---

  test "show returns 200 for a teammate's private submission" do
    mate = create_user('mate')
    create_team(@contest, @member, mate)
    sub = create_submission(mate, @problem)

    sign_in_as @member
    # GCS へ到達しないよう get_source を一時的に差し替える
    client = Utils::GoogleCloudStorageClient
    original = client.method(:get_source)
    client.define_singleton_method(:get_source) { |*| StringIO.new('int main() {}') }
    begin
      get api_contest_submission_url(contest_slug: @contest.slug, id: sub.id)
    ensure
      client.define_singleton_method(:get_source, original)
    end
    assert_response :success
  end

  test "show returns 403 for a private submission of a user in another team" do
    mate = create_user('mate')
    outsider = create_user('outsider')
    create_team(@contest, @member, mate)
    create_team(@contest, outsider)
    sub = create_submission(outsider, @problem)

    sign_in_as @member
    get api_contest_submission_url(contest_slug: @contest.slug, id: sub.id)
    assert_response :forbidden
  end

  # --- デバッグ提出（S7b） ---

  # Utils::GoogleCloudStorageClient の特異メソッドを一時的に差し替える
  def stub_gcs(name, impl)
    client = Utils::GoogleCloudStorageClient
    original = client.method(name)
    client.define_singleton_method(name, impl)
    yield
  ensure
    client.define_singleton_method(name, original)
  end

  def submit(problem, lang: 'cpp23', **query)
    post api_contest_task_submit_url(contest_slug: @contest.slug, task_slug: problem.slug, lang: lang, **query),
         params: 'int main(){}', headers: { 'CONTENT_TYPE' => 'text/plain' }
  end

  test "create marks a debug submission of the problem writer" do
    sign_in_as @writer
    stub_gcs(:upload_source, ->(*) {}) do
      assert_difference -> { Submission.count }, 2 do
        submit(@problem, debug: 1)
        assert_response :success
        submit(@problem)
        assert_response :success
      end
    end
    debug, normal = Submission.order(id: :desc).limit(2).to_a.reverse
    assert_equal 'all', debug.output_capture
    assert_nil normal.output_capture
  end

  test "create rejects a debug submission from a participant" do
    user = create_user('participant')
    Registration.create!(user: user, contest: @contest)
    assert @problem.has_permission?(user)

    sign_in_as user
    assert_no_difference -> { Submission.count } do
      submit(@problem, debug: 1)
    end
    assert_response :forbidden
  end

  # 提出できるのは active な言語の key だけ（S8。alias と旧言語は受け付けない）
  [
    ['an unknown lang', 'cpp'],
    ['an inactive language', 'python:3.11.4'],
    ['an alias of an active language', 'cpp23_gcc:12.2.0'],
    ['an empty lang', ''],
  ].each do |desc, lang|
    test "create rejects #{desc}" do
      sign_in_as @writer
      stub_gcs(:upload_source, ->(*) { flunk 'ソースをアップロードしてはいけない' }) do
        assert_no_difference -> { Submission.count } do
          submit(@problem, lang: lang)
        end
      end
      assert_response :unprocessable_content
      assert_equal 'この言語では提出できません。', JSON.parse(response.body)['error']
    end
  end

  test "create rejects a submission without lang" do
    sign_in_as @writer
    assert_no_difference -> { Submission.count } do
      post api_contest_task_submit_url(contest_slug: @contest.slug, task_slug: @problem.slug),
           params: 'int main(){}', headers: { 'CONTENT_TYPE' => 'text/plain' }
    end
    assert_response :unprocessable_content
  end

  test "create stores the key of an active language" do
    sign_in_as @writer
    stub_gcs(:upload_source, ->(*) {}) do
      submit(@problem, lang: 'python')
    end
    assert_response :success
    assert_equal 'python', Submission.order(:id).last.lang
  end

  OUTPUTS_META = {
    prefix: '1/01JTOKEN/1/',
    streams: {
      user_stdout: { size: 4, saved: 4, truncated: false },
      user_stderr: { size: nil, saved: 1_048_576, truncated: true },
      checker_stderr: { size: nil, saved: nil, truncated: false, error: 'upload' },
    },
  }.to_json

  # member の提出（writer_problem、公開）をデバッグ提出にして、結果を1件付ける
  def debug_result(created_at: Time.current)
    @member_submission.update_columns(output_capture: 'all', updated_at: 1.minute.from_now)
    TestcaseResult.create!(
      submission: @member_submission, testcase: testcases(:one), status: 'WA', score: 0,
      execution_time: 1, execution_memory: 1, outputs: OUTPUTS_META, created_at: created_at
    )
  end

  test "show gives the outputs of a debug submission to the writer" do
    result = debug_result
    sign_in_as @writer
    stub_gcs(:get_source, ->(*) { StringIO.new('int main(){}') }) do
      get api_contest_submission_url(contest_slug: @contest.slug, id: @member_submission.id)
    end
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal true, body['debug']
    tr = body['testcase_results'].first
    assert_equal result.id, tr['id']
    assert_equal false, tr.dig('outputs', 'expired')
    assert_equal(
      [
        { 'stream' => 'user_stdout', 'size' => 4, 'saved' => 4, 'truncated' => false, 'error' => nil },
        { 'stream' => 'user_stderr', 'size' => nil, 'saved' => 1_048_576, 'truncated' => true, 'error' => nil },
        { 'stream' => 'checker_stderr', 'size' => nil, 'saved' => nil, 'truncated' => false, 'error' => 'upload' },
      ],
      tr.dig('outputs', 'streams')
    )
  end

  test "testcase results carry no outputs for people who cannot see them" do
    result = debug_result
    json = TestcaseResultSerializer.new(result, output_streams: []).as_json
    assert_not json.key?(:outputs)
    json = TestcaseResultSerializer.new(result, output_streams: %w[user_stdout]).as_json
    assert_equal %w[user_stdout], json[:outputs][:streams].map { |x| x[:stream] }
  end

  test "all marks debug submissions" do
    @member_submission.update_columns(output_capture: 'all')
    sign_in_as @admin
    get all_api_contest_submissions_url(contest_slug: @contest.slug)
    debug = JSON.parse(response.body)['data'].to_h { |s| [s['id'], s['debug']] }
    assert_equal({ @member_submission.id => true, @writer_submission.id => false }, debug)
  end

  def get_output(result, stream, **query)
    get output_api_contest_submission_url(
      contest_slug: @contest.slug, id: @member_submission.id, testcase_result_id: result.id, stream: stream, **query
    )
  end

  test "output returns the saved bytes to the writer" do
    result = debug_result
    sign_in_as @writer
    names = []
    stub_gcs(:get_judge_output, ->(name) { names << name; "c\xFFd\n".b }) do
      get_output(result, 'user_stdout')
      assert_response :success
      assert_equal "c\xFFd\n".b, response.body.b
      assert_match %r{\Atext/plain}, response.media_type
      assert_match(/\Ainline/, response.headers['Content-Disposition'])

      get_output(result, 'user_stderr', download: 1)
      assert_response :success
      assert_match(/\Aattachment/, response.headers['Content-Disposition'])
      assert_match(/#{@member_submission.id}_testcase_1_user_stderr\.txt/, response.headers['Content-Disposition'])
    end
    assert_equal ['1/01JTOKEN/1/user_stdout', '1/01JTOKEN/1/user_stderr'], names
  end

  test "output returns 403 to the submitter who is not a writer" do
    result = debug_result
    sign_in_as @member
    get_output(result, 'user_stdout')
    assert_response :forbidden
  end

  test "output returns 403 to anonymous users" do
    result = debug_result
    get_output(result, 'user_stdout')
    assert_response :forbidden
  end

  test "output returns 404 for unknown, unsaved or failed streams" do
    result = debug_result
    sign_in_as @writer
    get_output(result, 'secret')
    assert_response :not_found
    get_output(result, 'checker_stdout') # 保存していない
    assert_response :not_found
    get_output(result, 'checker_stderr') # 保存できなかった
    assert_response :not_found
    get output_api_contest_submission_url(
      contest_slug: @contest.slug, id: @member_submission.id, testcase_result_id: 0, stream: 'user_stdout'
    )
    assert_response :not_found
    get output_api_contest_submission_url(
      contest_slug: @ended_contest.slug, id: @member_submission.id, testcase_result_id: result.id, stream: 'user_stdout'
    )
    assert_response :not_found
  end

  test "output returns 410 after three days or when GCS no longer has it" do
    sign_in_as @writer
    stub_gcs(:get_judge_output, ->(*) { flunk 'GCS を見ない' }) do
      get_output(debug_result(created_at: 3.days.ago - 1.minute), 'user_stdout')
      assert_response :gone
    end
    stub_gcs(:get_judge_output, ->(*) { nil }) do
      get_output(debug_result, 'user_stdout')
      assert_response :gone
    end
  end
end
