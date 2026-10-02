# frozen_string_literal: true

require 'test_helper'

class ProblemPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @writer_problem = problems(:writer_problem)
    @admin_problem = problems(:admin_problem)
  end

  # --- initialize ---

  test "raises NotAuthorizedError for nil user" do
    assert_raises(Pundit::NotAuthorizedError) do
      ProblemPolicy.new(nil, Problem)
    end
  end

  # --- index? ---

  test "index? permits admin" do
    assert ProblemPolicy.new(@admin, Problem).index?
  end

  test "index? permits writer" do
    assert ProblemPolicy.new(@writer, Problem).index?
  end

  test "index? permits member" do
    assert ProblemPolicy.new(@member, Problem).index?
  end

  # --- show? ---

  test "show? permits admin for any problem" do
    assert ProblemPolicy.new(@admin, @writer_problem).show?
    assert ProblemPolicy.new(@admin, @admin_problem).show?
  end

  test "show? permits writer on their own problem" do
    assert ProblemPolicy.new(@writer, @writer_problem).show?
  end

  test "show? denies writer on another user's problem" do
    refute ProblemPolicy.new(@writer, @admin_problem).show?
  end

  test "show? denies member" do
    refute ProblemPolicy.new(@member, @writer_problem).show?
  end

  # --- create? ---

  test "create? permits admin" do
    assert ProblemPolicy.new(@admin, Problem).create?
  end

  test "create? permits writer" do
    assert ProblemPolicy.new(@writer, Problem).create?
  end

  test "create? denies member" do
    refute ProblemPolicy.new(@member, Problem).create?
  end

  # --- update? ---

  test "update? permits admin on any problem" do
    assert ProblemPolicy.new(@admin, @writer_problem).update?
  end

  test "update? permits writer on their own problem" do
    assert ProblemPolicy.new(@writer, @writer_problem).update?
  end

  test "update? denies writer on another user's problem" do
    refute ProblemPolicy.new(@writer, @admin_problem).update?
  end

  test "update? denies member" do
    refute ProblemPolicy.new(@member, @writer_problem).update?
  end

  # --- destroy? ---

  test "destroy? permits admin" do
    assert ProblemPolicy.new(@admin, @writer_problem).destroy?
  end

  test "destroy? denies writer" do
    refute ProblemPolicy.new(@writer, @writer_problem).destroy?
  end

  test "destroy? denies member" do
    refute ProblemPolicy.new(@member, @writer_problem).destroy?
  end

  # --- Scope ---

  test "scope returns all problems for admin" do
    scope = ProblemPolicy::Scope.new(@admin, Problem).resolve
    assert_includes scope, @writer_problem
    assert_includes scope, @admin_problem
  end

  test "scope returns only own problems for writer" do
    scope = ProblemPolicy::Scope.new(@writer, Problem).resolve
    assert_includes scope, @writer_problem
    refute_includes scope, @admin_problem
  end

  test "scope returns only own problems for member" do
    scope = ProblemPolicy::Scope.new(@member, Problem).resolve
    refute_includes scope, @writer_problem
    refute_includes scope, @admin_problem
  end
end
