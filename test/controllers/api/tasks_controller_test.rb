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

  # --- move ---

  def move_url(task_slug, position = nil)
    url = api_contest_task_move_url(contest_slug: @active_contest.slug, task_slug: task_slug)
    position ? "#{url}?position=#{position}" : url
  end

  test "move returns 401 when not authenticated" do
    put move_url(@writer_problem.slug, 'C')
    assert_response :unauthorized
  end

  test "move returns 403 for a member" do
    sign_in_as @member
    put move_url(@writer_problem.slug, 'C')
    assert_response :forbidden
  end

  test "move returns 400 without position" do
    sign_in_as @admin
    put move_url(@writer_problem.slug)
    assert_response :bad_request
    assert_equal({ 'error' => "パラメータ 'position' が必要です。" }, response.parsed_body)
  end

  test "move changes the position and slug for an empty position" do
    sign_in_as @admin
    put move_url(@writer_problem.slug, 'C')
    assert_response :no_content

    @writer_problem.reload
    assert_equal 'C', @writer_problem.position
    assert_equal "#{@active_contest.slug}_c", @writer_problem.slug
  end

  test "move swaps with the problem at the destination" do
    other = @writer_problem.dup
    other.update!(
      slug: "#{@active_contest.slug}_b", name: 'Other Problem', position: 'B',
      uuid: SecureRandom.uuid, writer_user: @admin
    )

    sign_in_as @admin
    put move_url(@writer_problem.slug, 'B')
    assert_response :no_content

    @writer_problem.reload
    other.reload
    assert_equal 'B', @writer_problem.position
    assert_equal "#{@active_contest.slug}_b", @writer_problem.slug
    assert_equal 'A', other.position
    assert_equal "#{@active_contest.slug}_a", other.slug
  end
end
