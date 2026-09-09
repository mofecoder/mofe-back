# frozen_string_literal: true

require 'test_helper'

class Api::PasswordsControllerTest < ActionDispatch::IntegrationTest
  REDIRECT_URL = 'http://localhost:8000/reset-password'

  def setup
    @user = users(:member_user)
    ActionMailer::Base.deliveries.clear
  end

  # --- create ---

  test "create sends a reset mail for a known address" do
    assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
      post api_user_password_url, params: { email: @user.email, redirect_url: REDIRECT_URL }
    end
    assert_response :success
    assert_equal 'パスワードリセットメールを送信しました。', JSON.parse(response.body)['message']
    assert @user.reload.reset_password_token.present?
  end

  test "create returns the same message for an unknown address without sending a mail" do
    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      post api_user_password_url, params: { email: 'nobody@example.com', redirect_url: REDIRECT_URL }
    end
    assert_response :success
    assert_equal 'パスワードリセットメールを送信しました。', JSON.parse(response.body)['message']
  end

  test "create returns 401 without a redirect_url" do
    post api_user_password_url, params: { email: @user.email }
    assert_response :unauthorized
  end

  # --- update ---

  test "update changes the password with a valid token" do
    token = @user.send_reset_password_instructions(redirect_url: REDIRECT_URL)

    patch api_user_password_url, params: {
      user: { password: 'new_password', password_confirmation: 'new_password', reset_password_token: token }
    }
    assert_response :success
    assert @user.reload.valid_password?('new_password')
  end

  test "update returns 400 without the user parameter" do
    patch api_user_password_url, params: { password: 'new_password' }
    assert_response :bad_request
  end

  # NOTE(既知バグ): update は User.reset_password_by_token の戻り値を検証しておらず、
  # トークンが不正でもパスワードを変更していないのに 200 と成功メッセージを返す。
  # 修正後は「現行挙動」ブロックを削除し、「修正後の想定挙動」のコメントを有効化すること。
  test "update reports success even for an invalid token" do
    patch api_user_password_url, params: {
      user: { password: 'new_password', password_confirmation: 'new_password', reset_password_token: 'invalid' }
    }

    # --- 現行挙動（バグ） ---
    assert_response :success
    assert_equal 'パスワードを変更しました。', JSON.parse(response.body)['message']
    # --- 修正後の想定挙動 ---
    # assert_response :unprocessable_entity

    # パスワード自体は変更されていない
    assert @user.reload.valid_password?('password')
  end
end
