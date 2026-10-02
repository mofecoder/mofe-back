# frozen_string_literal: true

require 'test_helper'

class Api::ProblemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @writer_problem = problems(:writer_problem)
    @admin_problem = problems(:admin_problem)
    @standalone_problem = problems(:standalone_problem)
  end

  # --- index ---

  test "index returns 401 when not authenticated" do
    get api_problems_url
    assert_response :unauthorized
  end

  test "index returns 403 for a member" do
    sign_in_as @member
    get api_problems_url
    assert_response :forbidden
  end

  test "index returns only the writer's own problems" do
    sign_in_as @writer
    get api_problems_url
    assert_response :success

    ids = JSON.parse(response.body).map { |p| p['id'] }
    assert_includes ids, @writer_problem.id
    assert_not_includes ids, @admin_problem.id
  end

  test "index returns every problem for an admin" do
    sign_in_as @admin
    get api_problems_url
    assert_response :success

    ids = JSON.parse(response.body).map { |p| p['id'] }
    assert_includes ids, @writer_problem.id
    assert_includes ids, @admin_problem.id
  end

  # --- show ---

  test "show returns 401 when not authenticated" do
    get api_problem_url(id: @writer_problem.id)
    assert_response :unauthorized
  end

  test "show returns 403 for a member" do
    sign_in_as @member
    get api_problem_url(id: @writer_problem.id)
    assert_response :forbidden
  end

  test "show returns 200 for the problem writer" do
    sign_in_as @writer
    get api_problem_url(id: @writer_problem.id)
    assert_response :success
    assert_equal @writer_problem.id, JSON.parse(response.body)['id']
  end

  test "show returns 200 for an approved tester" do
    TesterRelation.create!(problem: @writer_problem, user: @member, approved: true)

    sign_in_as @member
    get api_problem_url(id: @writer_problem.id)
    assert_response :success
  end

  test "show returns 403 for a tester who is not approved yet" do
    TesterRelation.create!(problem: @writer_problem, user: @member, approved: false)

    sign_in_as @member
    get api_problem_url(id: @writer_problem.id)
    assert_response :forbidden
  end

  test "show returns 200 for an admin" do
    sign_in_as @admin
    get api_problem_url(id: @writer_problem.id)
    assert_response :success
  end

  test "show returns 404 for an unknown problem" do
    sign_in_as @admin
    get api_problem_url(id: 0)
    assert_response :not_found
  end

  # --- create ---

  test "create returns 401 when not authenticated" do
    post api_problems_url, params: { problem: valid_problem_params }
    assert_response :unauthorized
  end

  test "create returns 403 for a member" do
    sign_in_as @member
    post api_problems_url, params: { problem: valid_problem_params }
    assert_response :forbidden
  end

  test "create succeeds for a writer" do
    sign_in_as @writer
    assert_difference -> { Problem.count }, 1 do
      post api_problems_url, params: { problem: valid_problem_params }
    end
    assert_response :created

    created = Problem.find(JSON.parse(response.body)['id'])
    assert_equal @writer.id, created.writer_user_id
    assert created.uuid.present?
  end

  # --- update ---

  test "update returns 401 when not authenticated" do
    patch api_problem_url(id: @writer_problem.id), params: { problem: { name: 'Renamed' } }
    assert_response :unauthorized
  end

  test "update returns 403 for a member" do
    sign_in_as @member
    patch api_problem_url(id: @writer_problem.id), params: { problem: { name: 'Renamed' } }
    assert_response :forbidden
  end

  test "update returns 403 for a writer who does not own the problem" do
    sign_in_as @writer
    patch api_problem_url(id: @admin_problem.id), params: { problem: { name: 'Renamed' } }
    assert_response :forbidden
  end

  test "update succeeds for the problem writer" do
    sign_in_as @writer
    patch api_problem_url(id: @writer_problem.id), params: { problem: { name: 'Renamed' } }
    assert_response :success
    assert_equal 'Renamed', @writer_problem.reload.name
  end

  test "update returns 422 for invalid attributes" do
    sign_in_as @writer
    patch api_problem_url(id: @writer_problem.id), params: { problem: { submission_limit_1: -1 } }
    assert_response :unprocessable_entity
  end

  # --- download_checker / update_checker ---
  #
  # 成功パスは Google Cloud Storage にアクセスするためテストしない。
  # 権限チェックで早期リターンするケースのみを検証する。

  test "download_checker returns 401 when not authenticated" do
    get api_problem_checker_url(problem_id: @writer_problem.id)
    assert_response :unauthorized
  end

  test "download_checker returns 403 for a writer who does not own the problem" do
    sign_in_as @writer
    get api_problem_checker_url(problem_id: @admin_problem.id)
    assert_response :forbidden
  end

  test "update_checker returns 403 for a writer who does not own the problem" do
    sign_in_as @writer
    post api_problem_checker_url(problem_id: @admin_problem.id)
    assert_response :forbidden
  end

  private

  def valid_problem_params
    {
      name: 'New Problem', difficulty: 'easy', statement: 'statement',
      constraints: 'constraints', input_format: 'input', output_format: 'output'
    }
  end
end
