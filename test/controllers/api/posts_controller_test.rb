# frozen_string_literal: true

require 'test_helper'

class Api::PostsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @member = users(:member_user)
    @public_post = posts(:public_post)
    @private_post = posts(:private_post)
  end

  # --- index ---

  test "index returns only public posts for anonymous users" do
    get api_posts_url
    assert_response :success

    titles = JSON.parse(response.body).map { |p| p['title'] }
    assert_includes titles, @public_post.title
    assert_not_includes titles, @private_post.title
  end

  test "index returns only public posts for members" do
    sign_in_as @member
    get api_posts_url
    assert_response :success

    titles = JSON.parse(response.body).map { |p| p['title'] }
    assert_not_includes titles, @private_post.title
  end

  test "index returns private posts for admins" do
    sign_in_as @admin
    get api_posts_url
    assert_response :success

    titles = JSON.parse(response.body).map { |p| p['title'] }
    assert_includes titles, @private_post.title
  end

  test "index respects the count parameter" do
    get api_posts_url, params: { count: 1 }
    assert_response :success
    assert_equal 1, JSON.parse(response.body).length
  end

  # --- show ---

  test "show returns 200 for a public post" do
    get api_post_url(id: @public_post.id)
    assert_response :success
    assert_equal @public_post.title, JSON.parse(response.body)['title']
  end

  test "show returns 403 for a private post when not authenticated" do
    get api_post_url(id: @private_post.id)
    assert_response :forbidden
  end

  test "show returns 403 for a private post for a member" do
    sign_in_as @member
    get api_post_url(id: @private_post.id)
    assert_response :forbidden
  end

  test "show returns 200 for a private post for an admin" do
    sign_in_as @admin
    get api_post_url(id: @private_post.id)
    assert_response :success
  end

  test "show returns 404 for an unknown post" do
    get api_post_url(id: 0)
    assert_response :not_found
  end

  # --- create / update / destroy ---

  test "create returns 401 when not authenticated" do
    assert_no_difference -> { Post.count } do
      post api_posts_url, params: { post: { title: 'New', content: 'Body', public_status: 'public' } }
    end
    assert_response :unauthorized
  end

  test "create succeeds for an admin" do
    sign_in_as @admin
    assert_difference -> { Post.count }, 1 do
      post api_posts_url, params: { post: { title: 'New', content: 'Body', public_status: 'public' } }
    end
    assert_response :created
  end

  test "update returns 401 when not authenticated" do
    patch api_post_url(id: @public_post.id), params: { post: { title: 'Hijacked' } }

    assert_response :unauthorized
    assert_equal 'Public Post', @public_post.reload.title
  end

  test "update succeeds for an admin" do
    sign_in_as @admin
    patch api_post_url(id: @public_post.id), params: { post: { title: 'Updated' } }
    assert_response :no_content
    assert_equal 'Updated', @public_post.reload.title
  end

  test "destroy returns 401 when not authenticated" do
    delete api_post_url(id: @public_post.id)

    assert_response :unauthorized
    assert Post.exists?(@public_post.id)
  end

  test "destroy soft-deletes the post" do
    sign_in_as @admin
    delete api_post_url(id: @public_post.id)
    assert_response :no_content

    assert_not Post.exists?(@public_post.id)
    assert Post.with_discarded.exists?(@public_post.id)
  end
end
