# frozen_string_literal: true

require 'test_helper'

# CORS は Rack::Cors (config/initializers/cors.rb) が処理する
class CorsTest < ActionDispatch::IntegrationTest
  def preflight(origin)
    process :options, '/api/contests', headers: {
      'Origin' => origin,
      'Access-Control-Request-Method' => 'POST',
      'Access-Control-Request-Headers' => 'content-type,access-token'
    }
  end

  test "preflight from the production frontend is allowed" do
    preflight('https://mofecoder.com')

    assert_response :success
    assert_equal 'https://mofecoder.com', response.headers['Access-Control-Allow-Origin']
    assert_includes response.headers['Access-Control-Allow-Methods'], 'POST'
  end

  test "actual request from the production frontend exposes the auth headers" do
    get '/api/contests', headers: { 'Origin' => 'https://mofecoder.com' }

    assert_response :success
    assert_equal 'https://mofecoder.com', response.headers['Access-Control-Allow-Origin']
    assert_equal 'access-token, uid, client, expiry', response.headers['Access-Control-Expose-Headers']
  end

  # localhost は development 環境だけで許可する
  test "localhost is not allowed outside development" do
    preflight('http://localhost:8000')
    assert_nil response.headers['Access-Control-Allow-Origin']

    get '/api/contests', headers: { 'Origin' => 'http://localhost:8000' }
    assert_nil response.headers['Access-Control-Allow-Origin']
  end

  test "an unknown origin is not allowed" do
    preflight('https://evil.example.com')
    assert_nil response.headers['Access-Control-Allow-Origin']
  end
end
