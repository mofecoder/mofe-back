class ApplicationController < ActionController::API
  before_action :configure_permitted_parameters, if: :devise_controller?

  include DeviseTokenAuth::Concerns::SetUserByToken

  def render_404(e = nil)
    render json: { status: 404, error: e }, status: 404
  end

  def render_500(e = nil)
    render json: { status: 500, error: e }, status: 500
  end

  def admin?
    self.role == 'admin'
  end

  # @return [User]
  def current_user
    current_api_user
  end

  def authenticate_user!
    authenticate_api_user!
  end

  # @return [TrueClass | FalseClass]
  def user_signed_in?
    api_user_signed_in?
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :name, :password])
  end
end
