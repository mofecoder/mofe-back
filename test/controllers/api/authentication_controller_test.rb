# frozen_string_literal: true

require 'test_helper'

class Api::AuthenticationControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:member_user)
  end

  # --- sign_in ---

  test "sign_in succeeds with valid credentials" do
    post api_user_session_url, params: { email: @user.email, password: 'password' }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal @user.email, body.dig('data', 'email')
    assert_equal @user.name, body.dig('data', 'name')
  end

  test "sign_in returns auth headers on success" do
    post api_user_session_url, params: { email: @user.email, password: 'password' }
    assert_response :success

    auth_headers = extract_auth_headers(response)
    assert auth_headers['access-token'].present?, 'access-token header should be present'
    assert auth_headers['client'].present?, 'client header should be present'
    assert auth_headers['uid'].present?, 'uid header should be present'
  end

  test "sign_in fails with wrong password" do
    post api_user_session_url, params: { email: @user.email, password: 'wrong_password' }
    assert_response :unauthorized
  end

  test "sign_in fails with non-existent user" do
    post api_user_session_url, params: { email: 'noone@example.com', password: 'password' }
    assert_response :unauthorized
  end

  # --- sign_out ---

  test "sign_out succeeds with valid auth headers" do
    auth_headers = sign_in_via_api(@user)
    sign_out_via_api(auth_headers)
    assert_response :success
  end

  test "sign_out fails without auth headers" do
    delete destroy_api_user_session_url
    assert_response :not_found
  end

  # --- validate_token ---

  test "validate_token succeeds with valid auth headers" do
    auth_headers = sign_in_via_api(@user)
    get api_auth_validate_token_url, headers: auth_headers
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal @user.email, body.dig('data', 'email')
  end

  test "validate_token fails with invalid auth headers" do
    get api_auth_validate_token_url, headers: {
      'access-token' => 'invalid',
      'client' => 'invalid',
      'uid' => 'invalid'
    }
    assert_response :unauthorized
  end
end
