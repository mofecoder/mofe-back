# frozen_string_literal: true

require 'test_helper'

# NOTE(既知バグ): Api::SubmissionsController#_submit は権限が無い場合に render_403 したあと
# return しておらず、そのまま Google Cloud Storage へソースをアップロードして提出を保存してしまう。
# GCS に接続してしまうため create の成功パス／権限エラーパスはここではテストしていない。
# 修正後は「権限の無いユーザが submit しても Submission が作られない」テストを追加すること。
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
end
