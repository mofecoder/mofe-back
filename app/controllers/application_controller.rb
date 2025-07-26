class ApplicationController < ActionController::API
  rescue_from ActionController::RoutingError, with: :render_404

  before_action :verify_internal_request #, unless: -> { Rails.env.development? }
  before_action :set_user

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
    @current_user
  end

  def authenticate_user!
    unless user_signed_in?
      render_403
    end
  end

  def authenticate_admin_user!
    unless current_user&.admin?
      render_403
    end
  end

  # @return [Boolean]
  def user_signed_in?
    current_user.present?
  end

  private

  def verify_internal_request
    unless BFF_PUBLIC_KEY.present?
      render status: :service_unavailable, json: { error: 'BFF public key is not configured.' }
      return
    end

    body_digest = Digest::SHA256.hexdigest(request.raw_post)
    unless Utils::BffValidator.new(
      request.headers['X-Request-Signature'], request.headers['X-Request-Timestamp'],
      request.method, request.fullpath, body_digest
    ).validate
      render status: :forbidden, json: { error: 'Invalid request.' }
    end
  end

  def set_user
    uid = request.headers['X-User-Uid']
    @current_user = User.find_by(id: uid) if uid.present?
  end
end
