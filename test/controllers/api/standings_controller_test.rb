# frozen_string_literal: true

require 'test_helper'

class Api::StandingsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @contest = contests(:active_contest)
    @problem = problems(:writer_problem)
  end

  # --- index ---

  test "index returns 200 for anonymous users" do
    get api_contest_standings_url(contest_slug: @contest.slug)
    assert_response :success

    body = JSON.parse(response.body)
    assert_kind_of Array, body['problems']
    assert_kind_of Array, body['standings']
  end

  test "index returns an empty standings list when nobody is registered" do
    get api_contest_standings_url(contest_slug: @contest.slug)
    assert_response :success
    assert_empty JSON.parse(response.body)['standings']
  end

  test "index hides the problem name from users without permission" do
    get api_contest_standings_url(contest_slug: @contest.slug)
    assert_response :success

    problem = JSON.parse(response.body)['problems'].first
    assert_equal @problem.slug, problem['slug']
    assert_nil problem['name']
  end

  test "index exposes the problem name to the writer" do
    sign_in_as @writer
    get api_contest_standings_url(contest_slug: @contest.slug)
    assert_response :success
    assert_equal @problem.name, JSON.parse(response.body)['problems'].first['name']
  end

  test "index lists registered participants" do
    Registration.create!(user: @member, contest: @contest)

    sign_in_as @member
    get api_contest_standings_url(contest_slug: @contest.slug)
    assert_response :success

    standings = JSON.parse(response.body)['standings']
    assert_equal 1, standings.length
    assert_equal @member.name, standings.first.dig('user', 'name')
    assert_equal 1, standings.first['rank']
  end

  test "index counts an accepted submission of a registered participant" do
    Registration.create!(user: @member, contest: @contest)

    get api_contest_standings_url(contest_slug: @contest.slug)
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 1, body['problems'].first['solved']
    assert_equal 100, body['standings'].first.dig('result', 'score')
  end

  test "index returns 404 for an unknown contest" do
    get api_contest_standings_url(contest_slug: 'no-such-contest')
    assert_response :not_found
  end
end
