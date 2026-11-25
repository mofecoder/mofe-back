# frozen_string_literal: true

require 'test_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  # --- render_404 (catch-all ルート) ---

  test "unknown path returns 404 JSON" do
    get '/nonexistent'
    assert_response :not_found
    assert_kind_of String, JSON.parse(response.body)['error']
  end

  test "root path returns 404 JSON" do
    get '/'
    assert_response :not_found
    assert_kind_of String, JSON.parse(response.body)['error']
  end

  test "unknown path returns 404 for non-GET verbs" do
    post '/nonexistent'
    assert_response :not_found

    delete '/nonexistent'
    assert_response :not_found
  end

  # --- render_api_error / render_validation_error ---

  class ErrorTestController < ApplicationController
    def plain
      render_api_error('エラーです。', status: :bad_request)
    end

    def with_details
      render_api_error('エラーです。', status: :conflict, details: { name: ['は不正です。'] })
    end

    def validation
      user = User.new
      user.errors.add(:name, :blank)
      user.errors.add(:email, :blank)
      render_validation_error(user)
    end
  end

  def with_error_routes
    with_routing do |set|
      set.draw do
        %w[plain with_details validation].each do |action|
          get "/error_test/#{action}", to: "application_controller_test/error_test##{action}"
        end
      end
      yield
    end
  end

  test "render_api_error returns only the message when details are absent" do
    with_error_routes do
      get '/error_test/plain'
      assert_response :bad_request
      assert_equal({ 'error' => 'エラーです。' }, JSON.parse(response.body))
    end
  end

  test "render_api_error includes details when given" do
    with_error_routes do
      get '/error_test/with_details'
      assert_response :conflict
      assert_equal({ 'error' => 'エラーです。', 'details' => { 'name' => ['は不正です。'] } }, JSON.parse(response.body))
    end
  end

  test "render_validation_error returns full messages and per-field details" do
    with_error_routes do
      get '/error_test/validation'
      assert_response :unprocessable_content

      body = JSON.parse(response.body)
      user = User.new
      user.errors.add(:name, :blank)
      user.errors.add(:email, :blank)
      assert_equal user.errors.full_messages.join("\n"), body['error']
      assert_equal %w[email name], body['details'].keys.sort
      assert_kind_of Array, body['details']['name']
    end
  end

  test "pundit authorization errors use the unified format" do
    get all_api_contest_submissions_url(contest_slug: contests(:active_contest).slug)
    assert_response :forbidden
    assert_equal({ 'error' => '権限がありません。' }, JSON.parse(response.body))
  end
end
