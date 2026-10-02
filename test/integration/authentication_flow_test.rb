# frozen_string_literal: true

require 'test_helper'

class AuthenticationFlowTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:member_user)
    @admin = users(:admin_user)
  end

  test "full flow: sign_in -> access protected endpoint -> sign_out -> access denied" do
    # 1. ログイン
    auth_headers = sign_in_via_api(@user)
    assert_response :success
    assert auth_headers['access-token'].present?

    # 2. 認証トークンで保護エンドポイントにアクセス → 成功
    get v4_problems_url, headers: auth_headers
    assert_response :success

    # 3. ログアウト
    sign_out_via_api(auth_headers)
    assert_response :success

    # 4. 同じトークンで保護エンドポイントにアクセス → 拒否
    get v4_problems_url, headers: auth_headers
    assert_includes [401, 403], response.status,
      "Expected 401 or 403 after sign_out, got #{response.status}"
  end

  test "unauthenticated access to protected endpoint is rejected" do
    get v4_problems_url
    assert_response :forbidden
  end

  test "sign_in -> sign_out -> re-sign_in succeeds" do
    # 1. 初回ログイン
    auth_headers_1 = sign_in_via_api(@user)
    assert_response :success

    # 2. ログアウト
    sign_out_via_api(auth_headers_1)
    assert_response :success

    # 3. 再ログイン → 新しいトークンで保護エンドポイントにアクセス可能
    auth_headers_2 = sign_in_via_api(@user)
    assert_response :success

    get v4_problems_url, headers: auth_headers_2
    assert_response :success
  end

  test "different users get independent sessions" do
    # member ユーザーでログイン
    member_headers = sign_in_via_api(@user)
    assert_response :success

    # admin ユーザーでログイン
    admin_headers = sign_in_via_api(@admin)
    assert_response :success

    # 両方のトークンが独立して有効
    get v4_problems_url, headers: member_headers
    assert_response :success

    get v4_problems_url, headers: admin_headers
    assert_response :success

    # member をログアウトしても admin は有効
    sign_out_via_api(member_headers)
    assert_response :success

    get v4_problems_url, headers: admin_headers
    assert_response :success
  end
end
