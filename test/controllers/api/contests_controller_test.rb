# frozen_string_literal: true

require 'test_helper'

class Api::ContestsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @active_contest = contests(:active_contest)
    @ended_contest = contests(:ended_contest)
    @writer_problem = problems(:writer_problem)
    @standalone_problem = problems(:standalone_problem)
  end

  # --- index ---

  test "index returns 200 for anonymous users" do
    get api_contests_url
    assert_response :success

    body = JSON.parse(response.body)
    assert_kind_of Array, body['in_progress']
    assert_kind_of Array, body['future']
    assert_kind_of Array, body['past']
    assert_kind_of Array, body['permanent']
  end

  test "index classifies contests by period" do
    get api_contests_url
    assert_response :success

    body = JSON.parse(response.body)
    assert_includes body['in_progress'].map { |c| c['slug'] }, @active_contest.slug
    assert_includes body['past'].map { |c| c['slug'] }, @ended_contest.slug
  end

  test "index hides private contests from non-admins" do
    @active_contest.update!(kind: 'private')

    get api_contests_url
    assert_response :success
    assert_not_includes JSON.parse(response.body)['in_progress'].map { |c| c['slug'] }, @active_contest.slug
  end

  test "index shows private contests to admins" do
    @active_contest.update!(kind: 'private')

    sign_in_as @admin
    get api_contests_url
    assert_response :success
    assert_includes JSON.parse(response.body)['in_progress'].map { |c| c['slug'] }, @active_contest.slug
  end

  # --- show ---

  test "show returns 200 for anonymous users" do
    get api_contest_url(@active_contest)
    assert_response :success
    assert_equal @active_contest.slug, JSON.parse(response.body)['slug']
  end

  test "show hides tasks of a running contest from anonymous users" do
    get api_contest_url(@active_contest)
    assert_response :success
    assert_nil JSON.parse(response.body)['tasks']
  end

  test "show exposes tasks of an ended contest" do
    get api_contest_url(@ended_contest)
    assert_response :success
    assert_kind_of Array, JSON.parse(response.body)['tasks']
  end

  test "show returns 404 for an unknown slug" do
    get api_contest_url(slug: 'no-such-contest')
    assert_response :not_found
  end

  # --- create ---

  test "create returns 401 when not authenticated" do
    post api_contests_url, params: { contest: { name: 'New', slug: 'new-contest' } }
    assert_response :unauthorized
  end

  test "create returns 403 for a member" do
    sign_in_as @member
    post api_contests_url, params: { contest: { name: 'New', slug: 'new-contest' } }
    assert_response :forbidden
  end

  test "create returns 403 for a writer" do
    sign_in_as @writer
    post api_contests_url, params: { contest: { name: 'New', slug: 'new-contest' } }
    assert_response :forbidden
  end

  test "create succeeds for an admin" do
    sign_in_as @admin
    assert_difference -> { Contest.count }, 1 do
      post api_contests_url, params: { contest: { name: 'New Contest', slug: 'new-contest', kind: 'normal' } }
    end
    assert_response :created
  end

  # --- update ---

  test "update returns 401 when not authenticated" do
    patch api_contest_url(@active_contest), params: { contest: { name: 'Renamed' } }
    assert_response :unauthorized
  end

  test "update returns 403 for a member" do
    sign_in_as @member
    patch api_contest_url(@active_contest), params: { contest: { name: 'Renamed' } }
    assert_response :forbidden
  end

  test "update returns 403 for a writer who is not a contest admin" do
    sign_in_as @writer
    patch api_contest_url(@active_contest), params: { contest: { name: 'Renamed' } }
    assert_response :forbidden
  end

  test "update succeeds for an admin" do
    sign_in_as @admin
    patch api_contest_url(@active_contest), params: { contest: { name: 'Renamed' } }
    assert_response :no_content
    assert_equal 'Renamed', @active_contest.reload.name
  end

  test "update succeeds for a contest admin" do
    ContestAdmin.create!(contest: @active_contest, user: @writer)

    sign_in_as @writer
    patch api_contest_url(@active_contest), params: { contest: { name: 'Renamed' } }
    assert_response :no_content
  end

  # --- set_task ---

  test "set_task returns 401 when not authenticated" do
    put set_task_api_contest_url(@ended_contest), params: { problem_id: @standalone_problem.id }
    assert_response :unauthorized
  end

  test "set_task returns 400 when problem_id is missing" do
    sign_in_as @admin
    put set_task_api_contest_url(@ended_contest), params: { problem_slug: 'x', position: 'Z' }
    assert_response :bad_request
  end

  test "set_task returns 400 when problem_slug is missing" do
    sign_in_as @admin
    put set_task_api_contest_url(@ended_contest), params: { problem_id: @standalone_problem.id, position: 'Z' }
    assert_response :bad_request
  end

  test "set_task returns 400 when position is missing" do
    sign_in_as @admin
    put set_task_api_contest_url(@ended_contest), params: { problem_id: @standalone_problem.id, problem_slug: 'x' }
    assert_response :bad_request
  end

  test "set_task returns 409 when the problem already belongs to a contest" do
    sign_in_as @admin
    put set_task_api_contest_url(@ended_contest),
        params: { problem_id: @writer_problem.id, problem_slug: 'moved', position: 'Z' }
    assert_response :conflict
  end

  test "set_task assigns the problem to the contest for an admin" do
    sign_in_as @admin
    put set_task_api_contest_url(@ended_contest),
        params: { problem_id: @standalone_problem.id, problem_slug: 'assigned-problem', position: 'Z' }
    assert_response :no_content

    @standalone_problem.reload
    assert_equal @ended_contest.id, @standalone_problem.contest_id
    assert_equal 'assigned-problem', @standalone_problem.slug
    assert_equal 'Z', @standalone_problem.position
  end

  # NOTE(既知バグ): set_task は「他のユーザの問題は追加できません。」を render した後に
  # return しておらず、403 を返しつつ後続のトランザクションで割り当てを実行してしまう。
  # 修正後は「現行挙動」ブロックを削除し、「修正後の想定挙動」のコメントを有効化すること。
  test "set_task rejects a writer adding another user's problem" do
    other_problem = Problem.create!(
      name: 'Admin Unset Problem', difficulty: 'easy', statement: 's', constraints: 'c',
      input_format: 'i', output_format: 'o', writer_user: @admin
    )

    sign_in_as @writer
    put set_task_api_contest_url(@ended_contest),
        params: { problem_id: other_problem.id, problem_slug: 'stolen-problem', position: 'Z' }
    assert_response :forbidden

    other_problem.reload
    # --- 現行挙動（バグ）: 403 を返すのに割り当てが実行されてしまう ---
    assert_equal @ended_contest.id, other_problem.contest_id
    assert_equal 'stolen-problem', other_problem.slug
    # --- 修正後の想定挙動 ---
    # assert_nil other_problem.contest_id
    # assert_nil other_problem.slug
  end

  # --- rejudge ---

  test "rejudge returns 401 when not authenticated" do
    post api_contest_rejudge_url(contest_slug: @active_contest.slug),
         params: { submission_ids: [submissions(:member_submission).id] }
    assert_response :unauthorized
  end

  test "rejudge returns 403 for a member" do
    sign_in_as @member
    post api_contest_rejudge_url(contest_slug: @active_contest.slug),
         params: { submission_ids: [submissions(:member_submission).id] }
    assert_response :forbidden
  end

  test "rejudge resets the submission for an admin" do
    submission = submissions(:member_submission)

    sign_in_as @admin
    post api_contest_rejudge_url(contest_slug: @active_contest.slug),
         params: { submission_ids: [submission.id] }
    assert_response :no_content

    submission.reload
    assert_equal 'WR', submission.status
    assert_nil submission.point
  end

  test "rejudge returns 404 for an unknown contest" do
    sign_in_as @admin
    post api_contest_rejudge_url(contest_slug: 'no-such-contest'), params: { submission_ids: [] }
    assert_response :not_found
  end
end
