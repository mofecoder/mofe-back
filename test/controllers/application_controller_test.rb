# frozen_string_literal: true

require 'test_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  # --- render_404 (catch-all ルート) ---

  test "unknown path returns 404 JSON" do
    get '/nonexistent'
    assert_response :not_found
    assert_equal 404, JSON.parse(response.body)['status']
  end

  test "root path returns 404 JSON" do
    get '/'
    assert_response :not_found
    assert_equal 404, JSON.parse(response.body)['status']
  end

  test "unknown path returns 404 for non-GET verbs" do
    post '/nonexistent'
    assert_response :not_found

    delete '/nonexistent'
    assert_response :not_found
  end
end
