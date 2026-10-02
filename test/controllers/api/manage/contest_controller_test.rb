# frozen_string_literal: true

require 'test_helper'

class Api::Manage::ContestControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @active_contest = contests(:active_contest)
  end

  # --- index ---

  test "index returns 401 when not authenticated" do
    get api_manage_contests_url
    assert_response :unauthorized
  end

  test "index returns 403 for a member" do
    sign_in_as @member
    get api_manage_contests_url
    assert_response :forbidden
  end

  test "index returns 403 for a writer" do
    sign_in_as @writer
    get api_manage_contests_url
    assert_response :forbidden
  end

  test "index returns all contests for an admin" do
    sign_in_as @admin
    get api_manage_contests_url
    assert_response :success

    slugs = JSON.parse(response.body).map { |c| c['slug'] }
    assert_includes slugs, @active_contest.slug
    assert_includes slugs, contests(:ended_contest).slug
  end

  # --- show ---

  test "show returns 401 when not authenticated" do
    get api_manage_contest_url(slug: @active_contest.slug)
    assert_response :unauthorized
  end

  test "show returns 403 for a member" do
    sign_in_as @member
    get api_manage_contest_url(slug: @active_contest.slug)
    assert_response :forbidden
  end

  test "show returns 403 for a writer who is not a contest admin" do
    sign_in_as @writer
    get api_manage_contest_url(slug: @active_contest.slug)
    assert_response :forbidden
  end

  test "show returns 200 for a contest admin" do
    ContestAdmin.create!(contest: @active_contest, user: @writer)

    sign_in_as @writer
    get api_manage_contest_url(slug: @active_contest.slug)
    assert_response :success
  end

  test "show returns 200 for an admin" do
    sign_in_as @admin
    get api_manage_contest_url(slug: @active_contest.slug)
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal @active_contest.slug, body['slug']
    assert_kind_of Array, body['tasks']
    assert_kind_of Array, body['admins']
  end

  test "show returns 404 for an unknown slug" do
    sign_in_as @admin
    get api_manage_contest_url(slug: 'no-such-contest')
    assert_response :not_found
  end
end
