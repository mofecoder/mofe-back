class Api::ApplicationController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized

  rescue_from Pundit::NotAuthorizedError, with: :render_403
end
