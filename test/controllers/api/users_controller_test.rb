# frozen_string_literal: true

require 'test_helper'

class Api::UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
  end

  # --- index ---

  test "index returns 401 when not authenticated" do
    get api_users_url
    assert_response :unauthorized
  end

  test "index returns 403 for a member" do
    sign_in_as @member
    get api_users_url
    assert_response :forbidden
  end

  test "index returns 403 for a writer" do
    sign_in_as @writer
    get api_users_url
    assert_response :forbidden
  end

  test "index returns every user for an admin" do
    sign_in_as @admin
    get api_users_url
    assert_response :success

    names = JSON.parse(response.body).map { |u| u['name'] }
    assert_includes names, @member.name
    assert_includes names, @writer.name
  end

  # --- update ---

  test "update returns 401 when not authenticated" do
    patch api_user_url(id: @member.id), params: { user: { name: @member.name } }
    assert_response :unauthorized
  end

  test "update returns 403 when a member targets another user" do
    sign_in_as @member
    patch api_user_url(id: @admin.id), params: { user: { name: 'whatever' } }
    assert_response :forbidden
  end

  test "update succeeds when a member targets themselves" do
    sign_in_as @member
    patch api_user_url(id: @member.id), params: { user: { name: @member.name } }
    assert_response :no_content
  end

  test "update returns 409 when changing the name to a different one" do
    sign_in_as @member
    patch api_user_url(id: @member.id), params: { user: { name: 'newname' } }
    assert_response :conflict
    assert_equal 'member_test', @member.reload.name
  end

  test "update returns 409 when the name has already been capitalised once" do
    @member.update!(name: 'Member_test')

    sign_in_as @member
    patch api_user_url(id: @member.id), params: { user: { name: 'MEMBER_TEST' } }
    assert_response :conflict
  end

  test "update allows fixing the letter case of the name" do
    sign_in_as @member
    patch api_user_url(id: @member.id), params: { user: { name: 'Member_Test' } }
    assert_response :no_content
    assert_equal 'Member_Test', @member.reload.name
  end

  # --- update_admin ---

  test "update_admin returns 401 when not authenticated" do
    patch update_admin_api_user_url(id: @member.id), params: { user: { role: 'writer' } }
    assert_response :unauthorized
  end

  test "update_admin returns 403 for a member" do
    sign_in_as @member
    patch update_admin_api_user_url(id: @writer.id), params: { user: { role: 'admin' } }
    assert_response :forbidden
  end

  test "update_admin changes the role for an admin" do
    sign_in_as @admin
    patch update_admin_api_user_url(id: @member.id), params: { user: { role: 'writer' } }
    assert_response :no_content
    assert_equal 'writer', @member.reload.role
  end

  # --- generate_writer_request_code ---

  test "generate_writer_request_code returns 401 when not authenticated" do
    post generate_writer_request_code_api_user_url(id: @member.id)
    assert_response :unauthorized
  end

  test "generate_writer_request_code returns 403 when a member targets another user" do
    sign_in_as @member
    post generate_writer_request_code_api_user_url(id: @writer.id)
    assert_response :forbidden
    assert_nil @writer.reload.writer_request_code
  end

  test "generate_writer_request_code succeeds for oneself" do
    sign_in_as @member
    post generate_writer_request_code_api_user_url(id: @member.id)
    assert_response :no_content
    assert @member.reload.writer_request_code.present?
  end

  test "generate_writer_request_code succeeds for an admin targeting another user" do
    sign_in_as @admin
    post generate_writer_request_code_api_user_url(id: @member.id)
    assert_response :no_content
    assert @member.reload.writer_request_code.present?
  end

  test "generate_writer_request_code returns 409 when a code already exists" do
    @member.update!(writer_request_code: 'existing-code')

    sign_in_as @member
    post generate_writer_request_code_api_user_url(id: @member.id)
    assert_response :conflict

    assert_equal 'existing-code', @member.reload.writer_request_code
  end
end
