# frozen_string_literal: true

require 'test_helper'

# ログイン・サインアップ・パスワードリセット・参加登録のレート制限
# カウントは test_helper の setup で Rails.cache.clear して毎回 0 から数える
class Api::RateLimitTest < ActionDispatch::IntegrationTest
  REDIRECT_URL = 'http://localhost:8000/reset-password'
  MESSAGE = 'リクエストが多すぎます。しばらく待ってからやり直してください。'

  def setup
    @member = users(:member_user)
    @admin = users(:admin_user)
    @contest = contests(:active_contest)
  end

  # --- サインイン (10 回 / 3 分) ---

  test "sign_in returns 429 on the 11th attempt" do
    10.times do
      post api_user_session_url, params: { email: @member.email, password: 'wrong' }
      assert_response :unauthorized
    end

    post api_user_session_url, params: { email: @member.email, password: 'password' }
    assert_response :too_many_requests
    body = JSON.parse(response.body)
    assert_equal false, body['success']
    assert_equal [MESSAGE], body['errors']
    assert_nil response.headers['access-token']
  end

  test "sign_in limit resets after the window" do
    10.times { post api_user_session_url, params: { email: @member.email, password: 'wrong' } }

    travel 3.minutes + 1.second do
      post api_user_session_url, params: { email: @member.email, password: 'password' }
      assert_response :success
    end
  end

  test "sign_in limit is counted per IP" do
    10.times { post api_user_session_url, params: { email: @member.email, password: 'wrong' } }

    post api_user_session_url, params: { email: @member.email, password: 'password' },
         headers: { 'REMOTE_ADDR' => '192.0.2.10' }
    assert_response :success
  end

  # --- サインアップ (5 回 / 1 時間) ---

  test "sign_up returns 429 on the 6th attempt" do
    5.times do |i|
      post api_user_registration_url, params: {
        name: "ratelimit#{i}", email: "ratelimit#{i}@example.com",
        password: 'password', password_confirmation: 'password'
      }
      assert_response :success
    end

    assert_no_difference -> { User.count } do
      post api_user_registration_url, params: {
        name: 'ratelimit5', email: 'ratelimit5@example.com',
        password: 'password', password_confirmation: 'password'
      }
    end
    assert_response :too_many_requests
    assert_equal [MESSAGE], JSON.parse(response.body)['errors']
  end

  # --- パスワードリセット (create: 5 回 / 1 時間、update: 10 回 / 1 時間) ---

  test "password reset request returns 429 on the 6th attempt" do
    5.times do
      post api_user_password_url, params: { email: @member.email, redirect_url: REDIRECT_URL }
      assert_response :success
    end

    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      post api_user_password_url, params: { email: @member.email, redirect_url: REDIRECT_URL }
    end
    assert_response :too_many_requests
    assert_equal MESSAGE, JSON.parse(response.body)['error']
  end

  test "password update returns 429 on the 11th attempt" do
    params = { user: { reset_password_token: 'invalid', password: 'newpassword', password_confirmation: 'newpassword' } }
    10.times do
      put api_user_password_url, params: params
      assert_response :unprocessable_entity
    end

    put api_user_password_url, params: params
    assert_response :too_many_requests
    assert_equal MESSAGE, JSON.parse(response.body)['error']
  end

  test "password create and update are counted separately" do
    5.times { post api_user_password_url, params: { email: @member.email, redirect_url: REDIRECT_URL } }

    put api_user_password_url,
        params: { user: { reset_password_token: 'invalid', password: 'newpassword', password_confirmation: 'newpassword' } }
    assert_response :unprocessable_entity
  end

  # --- 参加登録 (create / team 合わせて 10 回 / 1 分、ユーザー単位) ---

  test "contest registration returns 429 on the 11th attempt" do
    @contest.update!(closed_password: 'secret')

    sign_in_as @member
    10.times do
      post api_contest_registrations_url(contest_slug: @contest.slug), params: { password: 'wrong' }
      assert_response :forbidden
    end

    assert_no_difference -> { @contest.registrations.count } do
      post api_contest_registrations_url(contest_slug: @contest.slug), params: { password: 'secret' }
    end
    assert_response :too_many_requests
    assert_equal MESSAGE, JSON.parse(response.body)['error']
  end

  test "team registration shares the limit with create" do
    @contest.update!(closed_password: 'secret', allow_team_registration: true)

    sign_in_as @member
    10.times { post api_contest_registrations_url(contest_slug: @contest.slug), params: { password: 'wrong' } }

    post team_api_contest_registrations_url(contest_slug: @contest.slug),
         params: { name: 'team', passphrase: 'pass', password: 'secret' }
    assert_response :too_many_requests
  end

  test "contest registration limit is counted per user" do
    @contest.update!(closed_password: 'secret')

    sign_in_as @member
    10.times { post api_contest_registrations_url(contest_slug: @contest.slug), params: { password: 'wrong' } }

    sign_in_as @admin
    post api_contest_registrations_url(contest_slug: @contest.slug), params: { password: 'secret' }
    assert_response :created
  end
end
