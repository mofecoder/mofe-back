class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from ActionController::RoutingError, with: :render_404
  rescue_from Exception, with: :render_500

  def render_404(e = nil)
    render json: e, status: 404
  end

  def render_500(e = nil)
    render json: e, status: 500
  end
end
