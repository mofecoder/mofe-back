# frozen_string_literal: true

require 'test_helper'

class PreflightRequestControllerTest < ActionDispatch::IntegrationTest
  # --- preflight ---

  test "preflight returns 200 for any path" do
    process(:options, '/api/contests')
    assert_response :success

    process(:options, '/api/whatever/nested/path')
    assert_response :success
  end

  test "preflight sets CORS headers" do
    process(:options, '/api/contests')

    assert_equal 'Accept,Origin,Content-Type,Authorization',
                 response.headers['Access-Control-Allow-Headers']
    assert_equal 'GET,OPTIONS', response.headers['Access-Control-Allow-Methods']
    assert_equal 'true', response.headers['Access-Control-Allow-Credentials']
  end

  test "preflight allows the production origin by default" do
    process(:options, '/api/contests')
    assert_equal 'https://mofecoder.com', response.headers['Access-Control-Allow-Origin']
  end

  test "preflight echoes back the local development origin" do
    process(:options, '/api/contests', headers: { 'origin' => 'http://localhost:8000' })
    assert_equal 'http://localhost:8000', response.headers['Access-Control-Allow-Origin']
  end

  test "preflight falls back to the production origin for unknown origins" do
    process(:options, '/api/contests', headers: { 'origin' => 'https://evil.example.com' })
    assert_equal 'https://mofecoder.com', response.headers['Access-Control-Allow-Origin']
  end
end
