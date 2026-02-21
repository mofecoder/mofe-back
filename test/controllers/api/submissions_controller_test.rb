require 'test_helper'

class Api::SubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ended_contest = contests(:ended_contest)
    @running_contest = contests(:running_contest)
    @ended_problem = problems(:ended_problem)
    @running_problem = problems(:running_problem)
    @public_submission = submissions(:public_submission)
    @private_submission = submissions(:private_submission)
    @other_user_submission = submissions(:other_user_submission)
    @running_contest_submission = submissions(:running_contest_submission)
    @admin_user = users(:admin_user)
    @writer_user = users(:writer_user)
    @general_user = users(:general_user)
    @other_user = users(:other_user)

    # Stub GCS get_source for show tests to avoid external dependency
    Utils::GoogleCloudStorageClient.define_singleton_method(:get_source) do |_file_name|
      StringIO.new("dummy source code")
    end
  end

  teardown do
    # Remove the stub if it was defined
    if Utils::GoogleCloudStorageClient.singleton_class.method_defined?(:get_source)
      Utils::GoogleCloudStorageClient.singleton_class.remove_method(:get_source)
    end
  end

  private

  def auth_headers(user)
    user.create_new_auth_token
  end

  # ============================================
  # GET /api/contests/:contest_slug/submissions
  # (index - user's own submissions)
  # ============================================

  public

  test "index: returns unauthorized when not signed in" do
    get api_contest_submissions_url(contest_slug: @ended_contest.slug), as: :json
    assert_response :unauthorized
  end

  test "index: returns own submissions for ended contest" do
    get api_contest_submissions_url(contest_slug: @ended_contest.slug),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?('data')
    assert json.key?('meta')

    data = json['data']
    # general_user has public_submission and private_submission on ended_problem
    assert_equal 2, data.length
    data.each do |submission|
      assert_equal @general_user.name, submission['user']['name']
    end
  end

  test "index: returns only own submissions, not other users'" do
    get api_contest_submissions_url(contest_slug: @ended_contest.slug),
        headers: auth_headers(@other_user),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    data = json['data']
    assert_equal 1, data.length
    assert_equal @other_user.name, data[0]['user']['name']
  end

  test "index: returns submissions for running contest" do
    get api_contest_submissions_url(contest_slug: @running_contest.slug),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    data = json['data']
    assert_equal 1, data.length
  end

  test "index: returns empty list when user has no submissions" do
    get api_contest_submissions_url(contest_slug: @ended_contest.slug),
        headers: auth_headers(@admin_user),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 0, json['data'].length
  end

  test "index: returns not found for non-existent contest" do
    get api_contest_submissions_url(contest_slug: 'nonexistent'),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :not_found
  end

  test "index: includes pagination metadata" do
    get api_contest_submissions_url(contest_slug: @ended_contest.slug),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    meta = json['meta']
    assert meta.key?('pagination')
    pagination = meta['pagination']
    assert pagination.key?('current')
    assert pagination.key?('pages')
    assert pagination.key?('count')
  end

  test "index: submission data includes expected fields" do
    get api_contest_submissions_url(contest_slug: @ended_contest.slug),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    submission = json['data'].first
    assert submission.key?('id')
    assert submission.key?('user')
    assert submission.key?('task')
    assert submission.key?('status')
    assert submission.key?('point')
    assert submission.key?('execution_time')
    assert submission.key?('lang')
    assert submission.key?('timestamp')
  end

  # ============================================
  # GET /api/contests/:contest_slug/submissions/all
  # (all submissions with visibility rules)
  # ============================================

  test "all: returns submissions for ended contest when not signed in" do
    get all_api_contest_submissions_url(contest_slug: @ended_contest.slug), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    data = json['data']
    # Only public submissions are visible to anonymous users
    data.each do |submission|
      assert_equal true, submission['public']
    end
  end

  test "all: returns forbidden for running contest when not signed in" do
    get all_api_contest_submissions_url(contest_slug: @running_contest.slug), as: :json
    assert_response :forbidden
  end

  test "all: returns forbidden for running contest for regular user" do
    get all_api_contest_submissions_url(contest_slug: @running_contest.slug),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :forbidden
  end

  test "all: returns submissions for ended contest when signed in" do
    get all_api_contest_submissions_url(contest_slug: @ended_contest.slug),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    data = json['data']
    # Signed-in user can see public submissions + own submissions
    assert data.length >= 1
  end

  test "all: admin can see all submissions for running contest" do
    get all_api_contest_submissions_url(contest_slug: @running_contest.slug),
        headers: auth_headers(@admin_user),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?('data')
  end

  test "all: writer can see submissions for running contest" do
    get all_api_contest_submissions_url(contest_slug: @running_contest.slug),
        headers: auth_headers(@writer_user),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?('data')
  end

  test "all: returns not found for non-existent contest" do
    get all_api_contest_submissions_url(contest_slug: 'nonexistent'), as: :json
    assert_response :not_found
  end

  test "all: includes pagination metadata" do
    get all_api_contest_submissions_url(contest_slug: @ended_contest.slug),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json['meta'].key?('pagination')
  end

  # ============================================
  # GET /api/contests/:contest_slug/submissions/:id
  # (show - submission detail)
  # ============================================

  test "show: owner can view own public submission in ended contest" do
    get api_contest_submission_url(contest_slug: @ended_contest.slug, id: @public_submission.id),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @public_submission.id, json['id']
  end

  test "show: owner can view own private submission in ended contest" do
    get api_contest_submission_url(contest_slug: @ended_contest.slug, id: @private_submission.id),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @private_submission.id, json['id']
  end

  test "show: anonymous user can view public submission in ended contest" do
    get api_contest_submission_url(contest_slug: @ended_contest.slug, id: @public_submission.id),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @public_submission.id, json['id']
  end

  test "show: anonymous user cannot view private submission in ended contest" do
    get api_contest_submission_url(contest_slug: @ended_contest.slug, id: @private_submission.id),
        as: :json
    assert_response :forbidden
  end

  test "show: other user cannot view private submission in ended contest" do
    get api_contest_submission_url(contest_slug: @ended_contest.slug, id: @private_submission.id),
        headers: auth_headers(@other_user),
        as: :json
    assert_response :forbidden
  end

  test "show: admin can view any submission" do
    get api_contest_submission_url(contest_slug: @ended_contest.slug, id: @private_submission.id),
        headers: auth_headers(@admin_user),
        as: :json
    assert_response :success
  end

  test "show: writer of the problem can view any submission on that problem" do
    get api_contest_submission_url(contest_slug: @ended_contest.slug, id: @private_submission.id),
        headers: auth_headers(@writer_user),
        as: :json
    assert_response :success
  end

  test "show: returns not found when contest_slug does not match submission's contest" do
    get api_contest_submission_url(contest_slug: @running_contest.slug, id: @public_submission.id),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :not_found
  end

  test "show: returns not found for non-existent submission" do
    get api_contest_submission_url(contest_slug: @ended_contest.slug, id: 999999),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :not_found
  end

  test "show: anonymous user cannot view submission in running contest" do
    get api_contest_submission_url(contest_slug: @running_contest.slug, id: @running_contest_submission.id),
        as: :json
    assert_response :forbidden
  end

  test "show: non-owner cannot view submission in running contest" do
    get api_contest_submission_url(contest_slug: @running_contest.slug, id: @running_contest_submission.id),
        headers: auth_headers(@other_user),
        as: :json
    assert_response :forbidden
  end

  test "show: owner can view own submission in running contest" do
    get api_contest_submission_url(contest_slug: @running_contest.slug, id: @running_contest_submission.id),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :success
  end

  test "show: response includes expected detail fields" do
    get api_contest_submission_url(contest_slug: @ended_contest.slug, id: @public_submission.id),
        headers: auth_headers(@general_user),
        as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?('id')
    assert json.key?('user')
    assert json.key?('task')
    assert json.key?('status')
    assert json.key?('point')
    assert json.key?('execution_time')
    assert json.key?('lang')
    assert json.key?('compile_error')
    assert json.key?('testcase_results')
    assert json.key?('testcase_sets')
  end
end
