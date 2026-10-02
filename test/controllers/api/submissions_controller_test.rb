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
         params: { lang: 'cpp' }
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
           params: { lang: 'cpp' }
    end
    assert_response :forbidden
  end
end
