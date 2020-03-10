class ApplicationController < ActionController::API
  rescue_from Exception, with: :render_500
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from ActionController::RoutingError, with: :render_404

  def render_404(e = nil)
    render json: { status: 404, error: e }, status: 404
  end

  def render_500(e = nil)
    render json: { status: 500, error: e }, status: 500
  end
end
