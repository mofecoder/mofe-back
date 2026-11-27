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

  test "index ignores debug submissions" do
    Registration.create!(user: @member, contest: @contest)
    submissions(:member_submission).update_columns(output_capture: 'all')

    get api_contest_standings_url(contest_slug: @contest.slug)
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 0, body['problems'].first['solved']
    assert_equal({}, body['standings'].first['problems'].first)
  end

  # --- index: 判定中の扱い ---

  JUDGE_TOKEN = '01HZX0000000000000000000AB'

  def first_problem_cell
    get api_contest_standings_url(contest_slug: @contest.slug)
    assert_response :success
    JSON.parse(response.body)['standings'].first['problems'].first
  end

  test "index treats a submission with a judge token as in progress even if its status is WA" do
    Registration.create!(user: @member, contest: @contest)
    submissions(:member_submission).update_columns(status: 'WA', point: 0, judge_token: JUDGE_TOKEN)

    # 判定中の提出は集計しないので、ペナルティにならない
    assert_equal({}, first_problem_cell)
  end

  test "index counts a WA submission without a judge token as before" do
    Registration.create!(user: @member, contest: @contest)
    submissions(:member_submission).update_columns(status: 'WA', point: 0, judge_token: nil)

    assert_equal({ 'penalty' => 1 }, first_problem_cell)
  end

  test "index marks a submission with a judge token as in progress in ICPC mode" do
    @contest.update_columns(standings_mode: Contest.standings_modes[:icpc])
    Registration.create!(user: @member, contest: @contest)
    submissions(:member_submission).update_columns(status: 'WA', point: 0, judge_token: JUDGE_TOKEN)

    assert_equal({ 'is_in_progress' => true }, first_problem_cell)
  end

  test "index does not mark a finished submission as in progress in ICPC mode" do
    @contest.update_columns(standings_mode: Contest.standings_modes[:icpc])
    Registration.create!(user: @member, contest: @contest)
    submissions(:member_submission).update_columns(status: 'WA', point: 0, judge_token: nil)

    assert_equal({ 'penalty' => 1, 'is_in_progress' => false }, first_problem_cell)
  end

  # --- index: フラグ ---

  def standing_names(query)
    get "#{api_contest_standings_url(contest_slug: @contest.slug)}#{query}"
    assert_response :success
    JSON.parse(response.body)['standings'].map { |s| s.dig('user', 'name') }
  end

  test "index excludes open registrations with exclude_open=true" do
    Registration.create!(user: @member, contest: @contest, open_registration: true)
    assert_empty standing_names('?exclude_open=true')
  end

  test "index excludes open registrations with a valueless exclude_open" do
    Registration.create!(user: @member, contest: @contest, open_registration: true)
    assert_empty standing_names('?exclude_open')
  end

  test "index includes open registrations with exclude_open=false" do
    Registration.create!(user: @member, contest: @contest, open_registration: true)
    assert_equal [@member.name], standing_names('?exclude_open=false')
    assert_equal [@member.name], standing_names('?exclude_open=0')
  end

  test "index shows only teams with team_only=true" do
    Registration.create!(user: @member, contest: @contest)
    assert_empty standing_names('?team_only=true')
    assert_equal [@member.name], standing_names('?team_only=false')
  end

  test "index returns 404 for an unknown contest" do
    get api_contest_standings_url(contest_slug: 'no-such-contest')
    assert_response :not_found
  end
end
