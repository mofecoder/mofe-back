class ApplicationController < ActionController::API
  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from ActionController::RoutingError, with: :render_404

  include DeviseTokenAuth::Concerns::SetUserByToken

  def render_404(e = nil)
    render_api_error(error_message(e, 'ページが見つかりません。'), status: :not_found)
  end

  def render_500(e = nil)
    render_api_error(error_message(e, 'サーバーエラーが発生しました。'), status: :internal_server_error)
  end

  def render_403(_e = nil)
    render_api_error('権限がありません。', status: :forbidden)
  end

  # エラーレスポンスの形式を統一する
  # devise_token_auth の render_error(status, message) と衝突しないよう別名にしている
  # 形式: { error: string, details?: { [field]: string[] } }
  def render_api_error(message, status:, details: nil)
    body = { error: message }
    body[:details] = details if details.present?
    render json: body, status: status
  end

  # ActiveModel のバリデーションエラーを統一形式で返す
  def render_validation_error(record, status: :unprocessable_content)
    render_api_error(record.errors.full_messages.join("\n"), status: status, details: record.errors.to_hash)
  end

  # @return [User]
  def current_user
    current_api_user
  end

  def authenticate_user!
    authenticate_api_user!
  end

  def authenticate_admin_user!
    unless current_user.admin?
      render_403
    end
  end

  # @return [TrueClass | FalseClass]
  def user_signed_in?
    api_user_signed_in?
  end

  private

  # 文字列ならそのまま、それ以外 (例外を含む) は既定のメッセージを返す
  # 例外のメッセージにはクラス名・SQL・内部のパスなどが入りうるので応答に含めない
  def error_message(e, default)
    e.is_a?(String) && e.present? ? e : default
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:name])
  end
end
