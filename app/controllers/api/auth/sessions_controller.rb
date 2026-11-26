# ログイン (POST /api/auth/sign_in) にレート制限を掛けるため devise_token_auth のコントローラを継承している
class Api::Auth::SessionsController < DeviseTokenAuth::SessionsController
  include Api::Auth::RateLimited

  # パスワードの総当たりを防ぐ (IP 単位)
  rate_limit to: 10, within: 3.minutes, only: :create, with: :render_auth_rate_limited
end
