class Api::Slack::SlackController < ApplicationController
  def add_writer
    if params[:token] != Rails.application.credentials.slack[:verification_token]
      render status: 401
      return
    end
    p request.headers
    p params[:text]
  end
end
