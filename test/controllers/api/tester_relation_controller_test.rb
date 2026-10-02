# frozen_string_literal: true

require 'test_helper'

class Api::TesterRelationControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @problem = problems(:writer_problem)
  end

  # --- set_problem (before_action) ---

  test "create returns 401 when not authenticated" do
    post api_problem_tester_relations_url(problem_id: @problem.id), params: { user_name: @member.name }
    assert_response :unauthorized
  end

  test "create returns 403 for a user who is neither writer nor contest admin" do
    sign_in_as @member
    post api_problem_tester_relations_url(problem_id: @problem.id), params: { user_name: @admin.name }
    assert_response :forbidden
  end

  test "create returns 404 for an unknown problem" do
    sign_in_as @admin
    post api_problem_tester_relations_url(problem_id: 0), params: { user_name: @member.name }
    assert_response :not_found
  end

  # --- create ---

  test "create adds a tester for the problem writer" do
    sign_in_as @writer
    assert_difference -> { @problem.tester_relations.count }, 1 do
      post api_problem_tester_relations_url(problem_id: @problem.id), params: { user_name: @member.name }
    end
    assert_response :created
    assert @problem.tester_relations.find_by(tester_user_id: @member.id).approved
  end

  test "create adds a tester for an admin" do
    sign_in_as @admin
    post api_problem_tester_relations_url(problem_id: @problem.id), params: { user_name: @member.name }
    assert_response :created
  end

  test "create returns 404 for an unknown user name" do
    sign_in_as @writer
    post api_problem_tester_relations_url(problem_id: @problem.id), params: { user_name: 'no_such_user' }
    assert_response :not_found
  end

  test "create returns 400 when the user is already a tester" do
    TesterRelation.create!(problem: @problem, user: @member, approved: true)

    sign_in_as @writer
    assert_no_difference -> { @problem.tester_relations.count } do
      post api_problem_tester_relations_url(problem_id: @problem.id), params: { user_name: @member.name }
    end
    assert_response :bad_request
  end

  # --- destroy ---

  test "destroy soft-deletes the tester relation" do
    relation = TesterRelation.create!(problem: @problem, user: @member, approved: true)

    sign_in_as @writer
    delete api_problem_tester_relations_url(problem_id: @problem.id), params: { user_name: @member.name }
    assert_response :no_content

    assert_not TesterRelation.exists?(relation.id)
    assert TesterRelation.with_discarded.exists?(relation.id)
  end

  test "destroy returns 404 when the user is not a tester" do
    sign_in_as @writer
    delete api_problem_tester_relations_url(problem_id: @problem.id), params: { user_name: @member.name }
    assert_response :not_found
  end

  test "destroy returns 404 for an unknown user name" do
    sign_in_as @writer
    delete api_problem_tester_relations_url(problem_id: @problem.id), params: { user_name: 'no_such_user' }
    assert_response :not_found
  end
end
