# サインアップ (POST /api/auth) にレート制限を掛けるため devise_token_auth のコントローラを継承している
# コンテストの参加登録 (Api::RegistrationsController) とは別物
class Api::Auth::RegistrationsController < DeviseTokenAuth::RegistrationsController
  include Api::Auth::RateLimited

  # アカウントの大量作成を防ぐ (IP 単位)
  rate_limit to: 5, within: 1.hour, only: :create, with: :render_auth_rate_limited
end
