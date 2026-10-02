# frozen_string_literal: true

require 'test_helper'

class Api::UserPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
  end

  test "does not raise for a nil user" do
    assert_nothing_raised { Api::UserPolicy.new(nil, @member).update? }
  end

  # --- admin 限定のアクション ---

  test "index?, update_admin? and update_rating? permit only admins" do
    %i[index? update_admin? update_rating?].each do |query|
      assert Api::UserPolicy.new(@admin, @member).public_send(query), query
      refute Api::UserPolicy.new(@writer, @member).public_send(query), query
      refute Api::UserPolicy.new(@member, @member).public_send(query), query
      refute Api::UserPolicy.new(nil, @member).public_send(query), query
    end
  end

  # --- 自分自身 or admin ---

  test "update? permits oneself" do
    assert Api::UserPolicy.new(@member, @member).update?
  end

  test "update? denies another user" do
    refute Api::UserPolicy.new(@member, @writer).update?
  end

  test "update? permits an admin targeting another user" do
    assert Api::UserPolicy.new(@admin, @member).update?
  end

  test "generate_writer_request_code? permits oneself and admins only" do
    assert Api::UserPolicy.new(@member, @member).generate_writer_request_code?
    assert Api::UserPolicy.new(@admin, @member).generate_writer_request_code?
    refute Api::UserPolicy.new(@member, @writer).generate_writer_request_code?
    refute Api::UserPolicy.new(nil, @member).generate_writer_request_code?
  end
end
