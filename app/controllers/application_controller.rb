class ApplicationController < ActionController::API
  before_action :configure_permitted_parameters, if: :devise_controller?
  rescue_from ActionController::RoutingError, with: :render_404

  include DeviseTokenAuth::Concerns::SetUserByToken

  def render_404(e = nil)
    render json: { status: 404, error: e }, status: 404
  end

  def render_500(e = nil)
    render json: { status: 500, error: e }, status: 500
  end

  def render_403
    render json: { error: '権限がありません。' }, status: :forbidden
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

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:name])
  end
end
