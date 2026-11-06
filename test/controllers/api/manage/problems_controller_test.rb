# frozen_string_literal: true

require 'test_helper'

class Api::Manage::ProblemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @standalone_problem = problems(:standalone_problem)
  end

  # --- unset_problems ---

  test "unset_problems returns 401 when not authenticated" do
    get unset_problems_api_manage_problems_url
    assert_response :unauthorized
  end

  test "unset_problems returns 403 for a member" do
    sign_in_as @member
    get unset_problems_api_manage_problems_url
    assert_response :forbidden
  end

  test "unset_problems returns only the writer's own problems" do
    other = Problem.create!(
      name: 'Admin Unset Problem', difficulty: 'easy', statement: 's', constraints: 'c',
      input_format: 'i', output_format: 'o', writer_user: @admin
    )

    sign_in_as @writer
    get unset_problems_api_manage_problems_url
    assert_response :success

    ids = JSON.parse(response.body).map { |p| p['id'] }
    assert_includes ids, @standalone_problem.id
    assert_not_includes ids, other.id
  end

  test "unset_problems returns every unassigned problem for an admin" do
    other = Problem.create!(
      name: 'Admin Unset Problem', difficulty: 'easy', statement: 's', constraints: 'c',
      input_format: 'i', output_format: 'o', writer_user: @admin
    )

    sign_in_as @admin
    get unset_problems_api_manage_problems_url
    assert_response :success

    ids = JSON.parse(response.body).map { |p| p['id'] }
    assert_includes ids, @standalone_problem.id
    assert_includes ids, other.id
  end

  test "unset_problems excludes problems that belong to a contest" do
    sign_in_as @admin
    get unset_problems_api_manage_problems_url
    assert_response :success

    ids = JSON.parse(response.body).map { |p| p['id'] }
    assert_not_includes ids, problems(:writer_problem).id
  end
end
