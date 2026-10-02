# frozen_string_literal: true

require 'test_helper'

class Api::ClarificationPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @active_contest = contests(:active_contest)
    @writer_problem = problems(:writer_problem)
    # 問題に紐付かない clarification
    @general = clarifications(:published_clarification)
    # writer_problem に紐付く clarification
    @on_problem = clarifications(:unpublished_clarification)
  end

  def create_user(name)
    User.create!(
      name: name, email: "#{name}@example.com",
      password: 'password', password_confirmation: 'password',
      provider: 'email', uid: "#{name}@example.com", role: 'member'
    )
  end

  def contest_admin
    @contest_admin ||= begin
      user = create_user('clar_admin')
      ContestAdmin.create!(contest: @active_contest, user: user)
      user
    end
  end

  # --- 未ログイン ---

  test "does not raise for a nil user" do
    assert_nothing_raised do
      Api::ClarificationPolicy.new(nil, @general).show?
      Api::ClarificationPolicy.new(nil, @on_problem).show?
    end
  end

  test "denies show? and create? to anonymous users" do
    refute Api::ClarificationPolicy.new(nil, @general).show?
    refute Api::ClarificationPolicy.new(nil, Clarification).create?
  end

  # --- index? / create? ---

  test "index? permits everyone" do
    assert Api::ClarificationPolicy.new(nil, Clarification).index?
    assert Api::ClarificationPolicy.new(@member, Clarification).index?
  end

  test "create? only requires a signed-in user" do
    assert Api::ClarificationPolicy.new(@member, Clarification).create?
  end

  # --- show? / update?（問題に紐付かない場合） ---

  test "show? permits only contest admins for a clarification without a problem" do
    assert Api::ClarificationPolicy.new(@admin, @general).show?
    assert Api::ClarificationPolicy.new(contest_admin, @general).show?
    refute Api::ClarificationPolicy.new(@writer, @general).show?
  end

  # NOTE: 質問者自身も参照できない（現行挙動をそのまま維持している）
  test "show? denies the author of a clarification without a problem" do
    assert_equal @member, @general.user
    refute Api::ClarificationPolicy.new(@member, @general).show?
  end

  # --- show? / update?（問題に紐付く場合） ---

  test "show? permits the writer of the related problem" do
    assert Api::ClarificationPolicy.new(@writer, @on_problem).show?
  end

  test "show? permits a tester of the related problem" do
    tester = create_user('clar_tester')
    TesterRelation.create!(problem: @writer_problem, user: tester, approved: true)

    assert Api::ClarificationPolicy.new(tester, @on_problem).show?
  end

  test "show? denies an unrelated member" do
    other = create_user('clar_other')
    refute Api::ClarificationPolicy.new(other, @on_problem).show?
  end

  test "update? follows the same rule as show?" do
    assert Api::ClarificationPolicy.new(@writer, @on_problem).update?
    refute Api::ClarificationPolicy.new(@member, @on_problem).update?
  end
end
