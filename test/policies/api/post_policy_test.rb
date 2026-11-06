# frozen_string_literal: true

require 'test_helper'

class Api::PostPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin_user)
    @member = users(:member_user)
    @public_post = posts(:public_post)
    @private_post = posts(:private_post)
  end

  # --- 未ログイン ---

  test "does not raise for a nil user" do
    assert_nothing_raised { Api::PostPolicy.new(nil, @public_post).show? }
  end

  # --- index? ---

  test "index? permits everyone" do
    assert Api::PostPolicy.new(nil, Post).index?
    assert Api::PostPolicy.new(@member, Post).index?
    assert Api::PostPolicy.new(@admin, Post).index?
  end

  # --- show? ---

  test "show? permits everyone for a public post" do
    assert Api::PostPolicy.new(nil, @public_post).show?
    assert Api::PostPolicy.new(@member, @public_post).show?
  end

  test "show? denies a private post to anonymous users and members" do
    refute Api::PostPolicy.new(nil, @private_post).show?
    refute Api::PostPolicy.new(@member, @private_post).show?
  end

  test "show? permits a private post for an admin" do
    assert Api::PostPolicy.new(@admin, @private_post).show?
  end

  # --- create? / update? / destroy? ---

  test "create?, update? and destroy? permit only admins" do
    %i[create? update? destroy?].each do |query|
      assert Api::PostPolicy.new(@admin, @public_post).public_send(query), query
      refute Api::PostPolicy.new(@member, @public_post).public_send(query), query
      refute Api::PostPolicy.new(nil, @public_post).public_send(query), query
    end
  end

  # --- Scope ---

  test "scope returns every post for an admin" do
    scope = Api::PostPolicy::Scope.new(@admin, Post).resolve
    assert_includes scope, @public_post
    assert_includes scope, @private_post
  end

  test "scope hides private posts from members and anonymous users" do
    [@member, nil].each do |user|
      scope = Api::PostPolicy::Scope.new(user, Post).resolve
      assert_includes scope, @public_post
      refute_includes scope, @private_post
    end
  end
end
