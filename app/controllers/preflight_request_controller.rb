class PreflightRequestController < ApplicationController
  ACCESS_CONTROL_ALLOW_METHODS = %w(GET OPTIONS).freeze
  ACCESS_CONTROL_ALLOW_HEADERS = %w(Accept Origin Content-Type Authorization).freeze

  def preflight
    origin = 'https://mofecoder.com'
    if request.headers['origin'] == 'http://localhost:8000'
      origin = 'http://localhost:8000'
    end
    puts "Origin: " + origin
    response.headers['Access-Control-Allow-Origin'] = origin
    set_preflight_headers!
    head :ok
  end

  private

  def set_preflight_headers!
    response.headers['Access-Control-Allow-Headers'] = ACCESS_CONTROL_ALLOW_HEADERS.join(',')
    response.headers['Access-Control-Allow-Methods'] = ACCESS_CONTROL_ALLOW_METHODS.join(',')
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end
end
