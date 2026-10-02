# frozen_string_literal: true

require 'test_helper'

class Api::ContestAdminsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @contest = contests(:active_contest)
  end

  # --- create ---

  test "create returns 401 when not authenticated" do
    post api_contest_contest_admins_url(contest_slug: @contest.slug), params: { user_name: @member.name }
    assert_response :unauthorized
  end

  test "create returns 403 for a member" do
    sign_in_as @member
    post api_contest_contest_admins_url(contest_slug: @contest.slug), params: { user_name: @writer.name }
    assert_response :forbidden
  end

  test "create returns 403 for a writer" do
    sign_in_as @writer
    post api_contest_contest_admins_url(contest_slug: @contest.slug), params: { user_name: @member.name }
    assert_response :forbidden
  end

  test "create adds a contest admin" do
    sign_in_as @admin
    assert_difference -> { @contest.contest_admins.count }, 1 do
      post api_contest_contest_admins_url(contest_slug: @contest.slug), params: { user_name: @writer.name }
    end
    assert_response :created
  end

  test "create returns 404 for an unknown user name" do
    sign_in_as @admin
    post api_contest_contest_admins_url(contest_slug: @contest.slug), params: { user_name: 'no_such_user' }
    assert_response :not_found
  end

  test "create returns 400 when the user is already a contest admin" do
    ContestAdmin.create!(contest: @contest, user: @writer)

    sign_in_as @admin
    assert_no_difference -> { @contest.contest_admins.count } do
      post api_contest_contest_admins_url(contest_slug: @contest.slug), params: { user_name: @writer.name }
    end
    assert_response :bad_request
  end

  test "create returns 404 for an unknown contest" do
    sign_in_as @admin
    post api_contest_contest_admins_url(contest_slug: 'no-such-contest'), params: { user_name: @writer.name }
    assert_response :not_found
  end

  # --- destroy ---

  test "destroy soft-deletes the contest admin" do
    contest_admin = ContestAdmin.create!(contest: @contest, user: @writer)

    sign_in_as @admin
    delete api_contest_contest_admins_url(contest_slug: @contest.slug), params: { user_name: @writer.name }
    assert_response :no_content

    assert_not ContestAdmin.exists?(contest_admin.id)
    assert ContestAdmin.with_discarded.exists?(contest_admin.id)
  end

  test "destroy returns 403 for a member" do
    sign_in_as @member
    delete api_contest_contest_admins_url(contest_slug: @contest.slug), params: { user_name: @writer.name }
    assert_response :forbidden
  end

  test "destroy returns 404 when the user is not a contest admin" do
    sign_in_as @admin
    delete api_contest_contest_admins_url(contest_slug: @contest.slug), params: { user_name: @writer.name }
    assert_response :not_found
  end
end
