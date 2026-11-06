# frozen_string_literal: true

require 'test_helper'

class V4::ProblemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @writer_problem = problems(:writer_problem)
    @standalone_problem = problems(:standalone_problem)
  end

  # --- Unauthenticated access ---

  test "index returns 403 when not authenticated" do
    get v4_problems_url
    assert_response :forbidden
  end

  test "show returns 403 when not authenticated" do
    get v4_problem_url(id: @writer_problem.id)
    assert_response :forbidden
  end

  # --- index ---

  test "index returns 200 for authenticated member" do
    sign_in_as @member
    get v4_problems_url
    assert_response :success
  end

  test "index returns 200 for authenticated admin" do
    sign_in_as @admin
    get v4_problems_url
    assert_response :success
  end

  test "index returns JSON array" do
    sign_in_as @admin
    get v4_problems_url
    assert_response :success
    body = JSON.parse(response.body)
    assert_kind_of Array, body
  end

  # --- show ---

  test "show returns 200 for admin" do
    sign_in_as @admin
    get v4_problem_url(id: @writer_problem.id)
    assert_response :success
  end

  test "show returns 200 for problem writer" do
    sign_in_as @writer
    get v4_problem_url(id: @writer_problem.id)
    assert_response :success
  end

  test "show returns 403 for member without access" do
    sign_in_as @member
    get v4_problem_url(id: @writer_problem.id)
    assert_response :forbidden
  end

  # --- destroy ---

  test "destroy returns 403 when not authenticated" do
    delete v4_problem_url(id: @standalone_problem.id)
    assert_response :forbidden
  end

  test "destroy returns 403 for non-admin" do
    sign_in_as @writer
    delete v4_problem_url(id: @standalone_problem.id)
    assert_response :forbidden
  end

  test "destroy succeeds for admin on standalone problem" do
    sign_in_as @admin
    delete v4_problem_url(id: @standalone_problem.id)
    assert_response :no_content
  end

  test "destroy fails for admin when problem belongs to contest" do
    sign_in_as @admin
    delete v4_problem_url(id: @writer_problem.id)
    assert_response :unprocessable_entity
  end
end
