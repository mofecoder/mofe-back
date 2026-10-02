# frozen_string_literal: true

require 'test_helper'

class Api::TopPageControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
  end

  # --- index ---

  test "index returns 200 for anonymous users" do
    get api_top_url
    assert_response :success

    body = JSON.parse(response.body)
    assert_kind_of Array, body['contests']
    assert_kind_of Array, body['posts']
  end

  test "index returns nil creating for anonymous users" do
    get api_top_url
    assert_response :success
    assert_nil JSON.parse(response.body)['creating']
  end

  test "index returns the problems being written for a writer" do
    sign_in_as @writer
    get api_top_url
    assert_response :success

    creating = JSON.parse(response.body)['creating']
    assert_kind_of Array, creating
    assert_includes creating.map { |p| p['name'] }, problems(:writer_problem).name
  end

  test "index returns an empty creating list for a member" do
    sign_in_as @member
    get api_top_url
    assert_response :success
    assert_empty JSON.parse(response.body)['creating']
  end

  test "index hides private posts from non-admins" do
    get api_top_url
    assert_response :success

    titles = JSON.parse(response.body)['posts'].map { |p| p['title'] }
    assert_includes titles, posts(:public_post).title
    assert_not_includes titles, posts(:private_post).title
  end

  test "index shows private posts to admins" do
    sign_in_as @admin
    get api_top_url
    assert_response :success

    titles = JSON.parse(response.body)['posts'].map { |p| p['title'] }
    assert_includes titles, posts(:private_post).title
  end
end
