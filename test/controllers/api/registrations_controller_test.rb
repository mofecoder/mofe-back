# frozen_string_literal: true

require 'test_helper'

class Api::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @member = users(:member_user)
    @contest = contests(:active_contest)
    @ended_contest = contests(:ended_contest)
  end

  # --- create ---

  test "create returns 401 when not authenticated" do
    post api_contest_registrations_url(contest_slug: @contest.slug)
    assert_response :unauthorized
  end

  test "create registers the member for a running contest" do
    sign_in_as @member
    assert_difference -> { @contest.registrations.count }, 1 do
      post api_contest_registrations_url(contest_slug: @contest.slug)
    end
    assert_response :created
  end

  test "create returns 409 when already registered" do
    Registration.create!(user: @member, contest: @contest)

    sign_in_as @member
    assert_no_difference -> { @contest.registrations.count } do
      post api_contest_registrations_url(contest_slug: @contest.slug)
    end
    assert_response :conflict
  end

  test "create returns 400 for an ended contest" do
    sign_in_as @member
    post api_contest_registrations_url(contest_slug: @ended_contest.slug)
    assert_response :bad_request
  end

  test "create returns 404 for an unknown contest" do
    sign_in_as @member
    post api_contest_registrations_url(contest_slug: 'no-such-contest')
    assert_response :not_found
  end

  test "create returns 403 when the password is missing for a closed contest" do
    @contest.update!(closed_password: 'secret')

    sign_in_as @member
    post api_contest_registrations_url(contest_slug: @contest.slug)
    assert_response :forbidden
  end

  test "create returns 403 when the password is wrong for a closed contest" do
    @contest.update!(closed_password: 'secret')

    sign_in_as @member
    post api_contest_registrations_url(contest_slug: @contest.slug), params: { password: 'wrong' }
    assert_response :forbidden
  end

  test "create succeeds with the right password for a closed contest" do
    @contest.update!(closed_password: 'secret')

    sign_in_as @member
    post api_contest_registrations_url(contest_slug: @contest.slug), params: { password: 'secret' }
    assert_response :created
  end

  # --- delete ---

  test "delete returns 401 when not authenticated" do
    delete api_contest_registrations_url(contest_slug: @contest.slug)
    assert_response :unauthorized
  end

  test "delete returns 404 when not registered" do
    sign_in_as @member
    delete api_contest_registrations_url(contest_slug: @contest.slug)
    assert_response :not_found
  end

  test "delete soft-deletes the registration" do
    registration = Registration.create!(user: @member, contest: @contest)

    sign_in_as @member
    delete api_contest_registrations_url(contest_slug: @contest.slug)
    assert_response :no_content

    assert_not Registration.exists?(registration.id)
    assert Registration.with_discarded.exists?(registration.id)
  end

  test "delete returns 400 for an ended contest" do
    sign_in_as @member
    delete api_contest_registrations_url(contest_slug: @ended_contest.slug)
    assert_response :bad_request
  end

  # --- team ---

  test "team returns 401 when not authenticated" do
    post team_api_contest_registrations_url(contest_slug: @contest.slug),
         params: { name: 'team_a', passphrase: 'pass' }
    assert_response :unauthorized
  end

  test "team creates a new team registration" do
    @contest.update!(allow_team_registration: true)

    sign_in_as @member
    assert_difference -> { TeamRegistration.count }, 1 do
      post team_api_contest_registrations_url(contest_slug: @contest.slug),
           params: { name: 'team_a', passphrase: 'pass' }
    end
    assert_response :success

    team = TeamRegistration.find_by!(contest: @contest, name: 'team_a')
    assert_equal [@member.id], team.team_registration_users.pluck(:user_id)
  end

  test "team returns 403 for a wrong passphrase" do
    @contest.update!(allow_team_registration: true)
    TeamRegistration.create!(contest: @contest, name: 'team_a', passphrase: 'pass')

    sign_in_as @member
    post team_api_contest_registrations_url(contest_slug: @contest.slug),
         params: { name: 'team_a', passphrase: 'wrong' }
    assert_response :forbidden
  end

  test "team returns 409 when the member already joined the team" do
    @contest.update!(allow_team_registration: true)
    team = TeamRegistration.create!(contest: @contest, name: 'team_a', passphrase: 'pass')
    team.team_registration_users.create!(user: @member)

    sign_in_as @member
    post team_api_contest_registrations_url(contest_slug: @contest.slug),
         params: { name: 'team_a', passphrase: 'pass' }
    assert_response :conflict
  end

  test "team returns 400 for an ended contest" do
    @ended_contest.update!(allow_team_registration: true)

    sign_in_as @member
    post team_api_contest_registrations_url(contest_slug: @ended_contest.slug),
         params: { name: 'team_a', passphrase: 'pass' }
    assert_response :bad_request
  end

  test "delete removes the member from the team and discards the empty team" do
    @contest.update!(allow_team_registration: true)
    team = TeamRegistration.create!(contest: @contest, name: 'team_a', passphrase: 'pass')
    team.team_registration_users.create!(user: @member)

    sign_in_as @member
    delete api_contest_registrations_url(contest_slug: @contest.slug)
    assert_response :success

    assert_not TeamRegistration.exists?(team.id)
    assert TeamRegistration.with_discarded.exists?(team.id)
  end

  test "team rejects registration when the contest does not allow teams" do
    assert_not @contest.allow_team_registration

    sign_in_as @member

    post team_api_contest_registrations_url(contest_slug: @contest.slug),
         params: { name: 'team_a', passphrase: 'pass' }
    assert_response :bad_request
    assert_not TeamRegistration.exists?(contest_id: @contest.id, name: 'team_a')
  end
end
