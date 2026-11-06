# frozen_string_literal: true

require 'test_helper'

class Api::TasksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @active_contest = contests(:active_contest)
    @ended_contest = contests(:ended_contest)
    @writer_problem = problems(:writer_problem)
    @admin_problem = problems(:admin_problem)
  end

  # --- show ---

  test "show returns 200 for anonymous users when the contest has ended" do
    get api_contest_task_url(contest_slug: @ended_contest.slug, slug: @admin_problem.slug)
    assert_response :success
    assert_equal @admin_problem.slug, JSON.parse(response.body)['slug']
  end

  test "show returns 403 for anonymous users while the contest is running" do
    get api_contest_task_url(contest_slug: @active_contest.slug, slug: @writer_problem.slug)
    assert_response :forbidden
  end

  test "show returns 403 for a member who is not registered" do
    sign_in_as @member
    get api_contest_task_url(contest_slug: @active_contest.slug, slug: @writer_problem.slug)
    assert_response :forbidden
  end

  test "show returns 200 for a registered member" do
    Registration.create!(user: @member, contest: @active_contest)

    sign_in_as @member
    get api_contest_task_url(contest_slug: @active_contest.slug, slug: @writer_problem.slug)
    assert_response :success
  end

  test "show returns 200 for the problem writer" do
    sign_in_as @writer
    get api_contest_task_url(contest_slug: @active_contest.slug, slug: @writer_problem.slug)
    assert_response :success
  end

  test "show returns 200 for an admin" do
    sign_in_as @admin
    get api_contest_task_url(contest_slug: @active_contest.slug, slug: @writer_problem.slug)
    assert_response :success
  end

  test "show returns 404 for an unknown contest" do
    get api_contest_task_url(contest_slug: 'no-such-contest', slug: @writer_problem.slug)
    assert_response :not_found
  end

  test "show returns 404 for an unknown task" do
    get api_contest_task_url(contest_slug: @active_contest.slug, slug: 'no-such-task')
    assert_response :not_found
  end

  # --- remove_from_contest ---

  test "remove_from_contest returns 401 when not authenticated" do
    put api_contest_task_remove_from_contest_url(contest_slug: @active_contest.slug, task_slug: @writer_problem.slug)
    assert_response :unauthorized
  end

  test "remove_from_contest returns 403 for a member" do
    sign_in_as @member
    put api_contest_task_remove_from_contest_url(contest_slug: @active_contest.slug, task_slug: @writer_problem.slug)
    assert_response :forbidden
  end

  test "remove_from_contest returns 403 for the problem writer" do
    sign_in_as @writer
    put api_contest_task_remove_from_contest_url(contest_slug: @active_contest.slug, task_slug: @writer_problem.slug)
    assert_response :forbidden
  end

  test "remove_from_contest detaches the problem for an admin" do
    sign_in_as @admin
    put api_contest_task_remove_from_contest_url(contest_slug: @active_contest.slug, task_slug: @writer_problem.slug)
    assert_response :no_content

    @writer_problem.reload
    assert_nil @writer_problem.contest_id
    assert_nil @writer_problem.slug
    assert_nil @writer_problem.position
  end
end
