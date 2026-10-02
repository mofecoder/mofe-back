# frozen_string_literal: true

module AuthenticationHelper
  # スタブ方式: コントローラーテスト用（Devise を経由しない）
  def sign_in_as(user)
    Thread.current[:test_current_user] = user
  end

  def sign_out_user
    Thread.current[:test_current_user] = nil
  end

  # API 方式: 実際の認証エンドポイント経由でログインし、トークンを取得
  # IDaaS 移行時はこのメソッドのエンドポイントとパラメータを変更する
  def sign_in_via_api(user, password: 'password')
    post api_user_session_url, params: { email: user.email, password: password }
    extract_auth_headers(response)
  end

  # 認証トークンで sign_out エンドポイントを呼び出す
  def sign_out_via_api(auth_headers)
    delete destroy_api_user_session_url, headers: auth_headers
  end

  # レスポンスヘッダーから認証情報を抽出
  # IDaaS 移行時はヘッダーキー名をここで変更する
  def extract_auth_headers(resp)
    {
      'access-token' => resp.headers['access-token'],
      'client' => resp.headers['client'],
      'uid' => resp.headers['uid']
    }.compact
  end

  def teardown
    Thread.current[:test_current_user] = nil
    super
  end
end
