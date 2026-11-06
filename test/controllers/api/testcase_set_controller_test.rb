# frozen_string_literal: true

require 'test_helper'

class Api::TestcaseSetControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @problem = problems(:writer_problem)
    @testcase_set = testcase_sets(:one)
  end

  # --- authenticate_writer! ---

  test "show returns 401 when not authenticated" do
    get api_problem_testcase_set_url(problem_id: @problem.id, id: @testcase_set.id)
    assert_response :unauthorized
  end

  test "show returns 403 for a member" do
    sign_in_as @member
    get api_problem_testcase_set_url(problem_id: @problem.id, id: @testcase_set.id)
    assert_response :forbidden
  end

  test "show returns 403 for a writer who does not own the problem" do
    sign_in_as @writer
    get api_problem_testcase_set_url(problem_id: problems(:admin_problem).id, id: testcase_sets(:two).id)
    assert_response :forbidden
  end

  # --- show ---

  test "show returns the testcase set for the problem writer" do
    sign_in_as @writer
    get api_problem_testcase_set_url(problem_id: @problem.id, id: @testcase_set.id)
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal @testcase_set.name, body['name']
    assert_equal @testcase_set.points, body['points']
  end

  # --- create ---

  test "create adds a testcase set" do
    sign_in_as @writer
    assert_difference -> { @problem.testcase_sets.count }, 1 do
      post api_problem_testcase_sets_url(problem_id: @problem.id),
           params: { testcase_set: { name: 'extra', points: 30 } }
    end
    assert_response :created
  end

  test "create returns 400 for a duplicated name" do
    sign_in_as @writer
    assert_no_difference -> { @problem.testcase_sets.count } do
      post api_problem_testcase_sets_url(problem_id: @problem.id),
           params: { testcase_set: { name: @testcase_set.name, points: 30 } }
    end
    assert_response :bad_request
  end

  # --- update ---

  test "update changes the points" do
    sign_in_as @writer
    patch api_problem_testcase_set_url(problem_id: @problem.id, id: @testcase_set.id),
          params: { testcase_set: { name: @testcase_set.name, points: 42 } }
    assert_response :no_content
    assert_equal 42, @testcase_set.reload.points
  end

  test "update refuses to rename the reserved 'all' set" do
    reserved = @problem.testcase_sets.create!(name: 'all', points: 100, is_sample: false)

    sign_in_as @writer
    patch api_problem_testcase_set_url(problem_id: @problem.id, id: reserved.id),
          params: { testcase_set: { name: 'renamed', points: 100 } }
    assert_response :bad_request
    assert_equal 'all', reserved.reload.name
  end

  test "update returns 400 when renaming to an existing name" do
    other = @problem.testcase_sets.create!(name: 'extra', points: 10, is_sample: false)

    sign_in_as @writer
    patch api_problem_testcase_set_url(problem_id: @problem.id, id: other.id),
          params: { testcase_set: { name: @testcase_set.name, points: 10 } }
    assert_response :bad_request
  end

  # --- destroy ---

  test "destroy soft-deletes the testcase set" do
    sign_in_as @writer
    delete api_problem_testcase_set_url(problem_id: @problem.id, id: @testcase_set.id)
    assert_response :no_content

    assert_not TestcaseSet.exists?(@testcase_set.id)
    assert TestcaseSet.with_discarded.exists?(@testcase_set.id)
  end

  test "destroy refuses to delete the reserved 'all' set" do
    reserved = @problem.testcase_sets.create!(name: 'all', points: 100, is_sample: false)

    sign_in_as @writer
    delete api_problem_testcase_set_url(problem_id: @problem.id, id: reserved.id)
    assert_response :bad_request
    assert TestcaseSet.exists?(reserved.id)
  end

  test "destroy refuses to delete the reserved 'sample' set" do
    reserved = @problem.testcase_sets.create!(name: 'sample', points: 0, is_sample: true)

    sign_in_as @writer
    delete api_problem_testcase_set_url(problem_id: @problem.id, id: reserved.id)
    assert_response :bad_request
    assert TestcaseSet.exists?(reserved.id)
  end
end
