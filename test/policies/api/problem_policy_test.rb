# frozen_string_literal: true

require 'test_helper'

class Api::ProblemPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @writer_problem = problems(:writer_problem)         # active_contest / writer_user
    @admin_problem = problems(:admin_problem)           # ended_contest / admin_user
    @standalone_problem = problems(:standalone_problem) # コンテスト未所属 / writer_user
  end

  def create_user(name, role: 'member')
    User.create!(
      name: name, email: "#{name}@example.com",
      password: 'password', password_confirmation: 'password',
      provider: 'email', uid: "#{name}@example.com", role: role
    )
  end

  def tester_of(problem, approved: true, name: 'tester_a')
    user = create_user(name)
    TesterRelation.create!(problem: problem, user: user, approved: approved)
    user
  end

  # --- 未ログイン ---

  test "does not raise for a nil user" do
    assert_nothing_raised do
      Api::ProblemPolicy.new(nil, @writer_problem).show?
      Api::ProblemPolicy.new(nil, @writer_problem).admin_or_writer?
      Api::ProblemPolicy.new(nil, @writer_problem).show_task?
      Api::ProblemPolicy.new(nil, Problem).index?
    end
  end

  test "denies every action to a nil user" do
    %i[index? create? show? update? manage_testcases? manage_testers? unset_problems?
       add_to_contest? admin_or_writer?].each do |query|
      refute Api::ProblemPolicy.new(nil, @writer_problem).public_send(query), query
    end
  end

  # --- コンテスト未所属の問題でも落ちないこと ---

  test "does not raise for a problem without a contest" do
    assert_nothing_raised do
      Api::ProblemPolicy.new(@writer, @standalone_problem).show?
      Api::ProblemPolicy.new(@writer, @standalone_problem).admin_or_writer?
    end
    assert Api::ProblemPolicy.new(@writer, @standalone_problem).show?
  end

  # --- index? / create? ---

  test "index? and create? permit admins and writers only" do
    %i[index? create?].each do |query|
      assert Api::ProblemPolicy.new(@admin, Problem).public_send(query), query
      assert Api::ProblemPolicy.new(@writer, Problem).public_send(query), query
      refute Api::ProblemPolicy.new(@member, Problem).public_send(query), query
    end
  end

  # --- show? ---

  test "show? permits an admin for any problem" do
    assert Api::ProblemPolicy.new(@admin, @writer_problem).show?
    assert Api::ProblemPolicy.new(@admin, @admin_problem).show?
  end

  test "show? permits the writer of the problem" do
    assert Api::ProblemPolicy.new(@writer, @writer_problem).show?
  end

  test "show? denies a writer on another user's problem" do
    refute Api::ProblemPolicy.new(@writer, @admin_problem).show?
  end

  test "show? permits an approved tester but denies an unapproved one" do
    approved = tester_of(@writer_problem, approved: true, name: 'tester_ok')
    unapproved = tester_of(@writer_problem, approved: false, name: 'tester_ng')

    assert Api::ProblemPolicy.new(approved, @writer_problem).show?
    refute Api::ProblemPolicy.new(unapproved, @writer_problem).show?
  end

  test "show? denies a member" do
    refute Api::ProblemPolicy.new(@member, @writer_problem).show?
  end

  # --- update? / manage_testers? ---

  test "update? permits the writer and admins but not testers" do
    tester = tester_of(@writer_problem)

    assert Api::ProblemPolicy.new(@admin, @writer_problem).update?
    assert Api::ProblemPolicy.new(@writer, @writer_problem).update?
    refute Api::ProblemPolicy.new(tester, @writer_problem).update?
    refute Api::ProblemPolicy.new(@member, @writer_problem).update?
  end

  test "manage_testers? follows the same rule as update?" do
    assert Api::ProblemPolicy.new(@writer, @writer_problem).manage_testers?
    refute Api::ProblemPolicy.new(@member, @writer_problem).manage_testers?
  end

  test "download_checker? and update_checker? follow the same rule as update?" do
    %i[download_checker? update_checker?].each do |query|
      assert Api::ProblemPolicy.new(@writer, @writer_problem).public_send(query), query
      refute Api::ProblemPolicy.new(@member, @writer_problem).public_send(query), query
    end
  end

  # --- manage_testcases? ---

  test "manage_testcases? permits the writer and admins" do
    assert Api::ProblemPolicy.new(@admin, @writer_problem).manage_testcases?
    assert Api::ProblemPolicy.new(@writer, @writer_problem).manage_testcases?
    refute Api::ProblemPolicy.new(@member, @writer_problem).manage_testcases?
  end

  # NOTE: 現行実装は writer ロールを要求するため、member ロールのまま writer_user に
  # なっているユーザは自分の問題のテストケースを操作できない。挙動を維持している。
  test "manage_testcases? denies a member-role user who owns the problem" do
    owner = create_user('owner_member', role: 'member')
    problem = Problem.create!(
      name: 'Member Owned', difficulty: 'easy', statement: 's', constraints: 'c',
      input_format: 'i', output_format: 'o', writer_user: owner
    )

    refute Api::ProblemPolicy.new(owner, problem).manage_testcases?
    assert Api::ProblemPolicy.new(owner, problem).update?
  end

  # --- add_to_contest? ---

  test "add_to_contest? denies a writer adding another user's problem" do
    assert Api::ProblemPolicy.new(@writer, @writer_problem).add_to_contest?
    refute Api::ProblemPolicy.new(@writer, @admin_problem).add_to_contest?
  end

  # NOTE: 判定が writer ロールにしか掛かっていないため、admin と member は通る（現行挙動）
  test "add_to_contest? permits non-writer roles for any problem" do
    assert Api::ProblemPolicy.new(@admin, @writer_problem).add_to_contest?
    assert Api::ProblemPolicy.new(@member, @admin_problem).add_to_contest?
  end

  # --- unset_problems? ---

  test "unset_problems? permits everyone but members" do
    assert Api::ProblemPolicy.new(@admin, Problem).unset_problems?
    assert Api::ProblemPolicy.new(@writer, Problem).unset_problems?
    refute Api::ProblemPolicy.new(@member, Problem).unset_problems?
  end

  # --- admin_or_writer? ---

  test "admin_or_writer? permits admins, the writer and approved testers" do
    tester = tester_of(@writer_problem)

    assert Api::ProblemPolicy.new(@admin, @writer_problem).admin_or_writer?
    assert Api::ProblemPolicy.new(@writer, @writer_problem).admin_or_writer?
    assert Api::ProblemPolicy.new(tester, @writer_problem).admin_or_writer?
    refute Api::ProblemPolicy.new(@member, @writer_problem).admin_or_writer?
  end

  test "admin_or_writer? permits a contest admin of the problem's contest regardless of role" do
    %w[member writer].each do |role|
      user = create_user("contest_admin_#{role}", role: role)
      ContestAdmin.create!(user: user, contest: @writer_problem.contest)

      assert Api::ProblemPolicy.new(user, @writer_problem).admin_or_writer?, role
    end
  end

  test "admin_or_writer? denies a contest admin of another contest" do
    user = create_user('other_contest_admin', role: 'writer')
    ContestAdmin.create!(user: user, contest: @admin_problem.contest)

    refute Api::ProblemPolicy.new(user, @writer_problem).admin_or_writer?
  end

  # --- show_task? / submit? ---

  test "show_task? delegates to Problem#has_permission?" do
    # ended_contest の問題は誰でも閲覧できる
    assert Api::ProblemPolicy.new(nil, @admin_problem).show_task?
    # 開催中のコンテストに未登録の member は閲覧できない
    refute Api::ProblemPolicy.new(@member, @writer_problem).show_task?
  end

  test "submit? delegates to Problem#has_permission?" do
    assert Api::ProblemPolicy.new(@writer, @writer_problem).submit?
    refute Api::ProblemPolicy.new(@member, @writer_problem).submit?
  end

  # --- Scope ---

  test "scope returns every problem for an admin" do
    scope = Api::ProblemPolicy::Scope.new(@admin, Problem).resolve
    assert_includes scope, @writer_problem
    assert_includes scope, @admin_problem
  end

  test "scope returns only the user's own problems otherwise" do
    scope = Api::ProblemPolicy::Scope.new(@writer, Problem).resolve
    assert_includes scope, @writer_problem
    refute_includes scope, @admin_problem
  end

  test "scope is empty for anonymous users" do
    scope = Api::ProblemPolicy::Scope.new(nil, Problem).resolve
    assert_empty scope
  end
end
