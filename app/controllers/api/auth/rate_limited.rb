# devise_token_auth のコントローラ向けのレート制限の応答
# フロントの getAuthErrors が読めるよう devise_token_auth と同じ { success: false, errors: [...] } で返す
module Api::Auth::RateLimited
  RATE_LIMIT_MESSAGE = 'リクエストが多すぎます。しばらく待ってからやり直してください。'

  private

  def render_auth_rate_limited
    render json: { success: false, errors: [RATE_LIMIT_MESSAGE] }, status: :too_many_requests
  end
end
