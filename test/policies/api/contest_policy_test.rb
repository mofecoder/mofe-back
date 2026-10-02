# frozen_string_literal: true

require 'test_helper'

class Api::ContestPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @active_contest = contests(:active_contest)  # 開催中
    @ended_contest = contests(:ended_contest)    # 終了済み
    @writer_problem = problems(:writer_problem)  # active_contest / writer_user
  end

  def create_user(name)
    User.create!(
      name: name, email: "#{name}@example.com",
      password: 'password', password_confirmation: 'password',
      provider: 'email', uid: "#{name}@example.com", role: 'member'
    )
  end

  # サイト管理者ではないコンテスト管理者
  def contest_admin
    @contest_admin ||= begin
      user = create_user('cadmin')
      ContestAdmin.create!(contest: @active_contest, user: user)
      user
    end
  end

  # --- 未ログイン ---

  test "does not raise for a nil user" do
    policy = Api::ContestPolicy.new(nil, @active_contest)
    assert_nothing_raised do
      policy.show?
      policy.contest_admin?
      policy.include_tasks?
      policy.show_editorial?
      policy.show_problems?
      policy.rejudge?
      policy.visible_submission_problem_ids
    end
  end

  # --- 公開アクション ---

  test "index?, show? and standings? permit everyone" do
    %i[index? show? standings?].each do |query|
      assert Api::ContestPolicy.new(nil, @active_contest).public_send(query), query
      assert Api::ContestPolicy.new(@member, @active_contest).public_send(query), query
    end
  end

  # --- サイト管理者限定 ---

  test "create?, tasks_index?, manage_index? and manage_admins? permit only site admins" do
    %i[create? tasks_index? manage_index? manage_admins?].each do |query|
      assert Api::ContestPolicy.new(@admin, @active_contest).public_send(query), query
      refute Api::ContestPolicy.new(contest_admin, @active_contest).public_send(query), query
      refute Api::ContestPolicy.new(@member, @active_contest).public_send(query), query
      refute Api::ContestPolicy.new(nil, @active_contest).public_send(query), query
    end
  end

  # --- コンテスト管理者 ---

  test "update?, manage_show? and remove_task? permit contest admins and site admins" do
    %i[update? manage_show? remove_task?].each do |query|
      assert Api::ContestPolicy.new(@admin, @active_contest).public_send(query), query
      assert Api::ContestPolicy.new(contest_admin, @active_contest).public_send(query), query
      refute Api::ContestPolicy.new(@member, @active_contest).public_send(query), query
      refute Api::ContestPolicy.new(nil, @active_contest).public_send(query), query
    end
  end

  test "contest_admin? is scoped to the contest" do
    assert Api::ContestPolicy.new(contest_admin, @active_contest).contest_admin?
    refute Api::ContestPolicy.new(contest_admin, @ended_contest).contest_admin?
  end

  # --- ログイン済みなら誰でも ---

  # NOTE: set_task はコンテスト管理者チェックが無い（現行挙動をそのまま維持している）
  test "set_task?, submissions? and register? only require a signed-in user" do
    %i[set_task? submissions? register? register_team? unregister?].each do |query|
      assert Api::ContestPolicy.new(@member, @active_contest).public_send(query), query
      refute Api::ContestPolicy.new(nil, @active_contest).public_send(query), query
    end
  end

  # --- rejudge? ---

  test "rejudge? permits writers, testers and contest admins" do
    assert Api::ContestPolicy.new(@writer, @active_contest).rejudge?
    assert Api::ContestPolicy.new(contest_admin, @active_contest).rejudge?
    assert Api::ContestPolicy.new(@admin, @active_contest).rejudge?
    refute Api::ContestPolicy.new(@member, @active_contest).rejudge?
    refute Api::ContestPolicy.new(nil, @active_contest).rejudge?
  end

  # --- 表示用の述語 ---

  test "include_tasks? is true once the contest has ended" do
    assert Api::ContestPolicy.new(nil, @ended_contest).include_tasks?
  end

  test "include_tasks? is false for an unregistered user during the contest" do
    refute Api::ContestPolicy.new(nil, @active_contest).include_tasks?
    refute Api::ContestPolicy.new(@member, @active_contest).include_tasks?
  end

  test "include_tasks? is true for a registered user during the contest" do
    Registration.create!(contest: @active_contest, user: @member)
    assert Api::ContestPolicy.new(@member, @active_contest).include_tasks?
  end

  test "include_tasks? is true for a contest admin during the contest" do
    assert Api::ContestPolicy.new(contest_admin, @active_contest).include_tasks?
  end

  test "show_editorial? requires the contest to have ended or a contest admin" do
    assert Api::ContestPolicy.new(nil, @ended_contest).show_editorial?
    refute Api::ContestPolicy.new(@member, @active_contest).show_editorial?
    assert Api::ContestPolicy.new(contest_admin, @active_contest).show_editorial?
  end

  test "show_problems? is true once the contest has started" do
    assert Api::ContestPolicy.new(nil, @active_contest).show_problems?
  end

  test "show_problems? is false before the start except for writers and testers" do
    future = Contest.create!(
      name: 'Future Contest', slug: 'future-contest', kind: 'normal', standings_mode: 1,
      start_at: 1.day.from_now, end_at: 2.days.from_now, penalty_time: 5
    )

    refute Api::ContestPolicy.new(@member, future).show_problems?
    assert Api::ContestPolicy.new(@admin, future).show_problems?
  end

  # --- visible_submission_problem_ids ---

  test "visible_submission_problem_ids returns every problem once the contest has ended" do
    assert_equal @ended_contest.problems.pluck(:id).sort,
                 Api::ContestPolicy.new(nil, @ended_contest).visible_submission_problem_ids.sort
  end

  test "visible_submission_problem_ids is empty for an outsider during the contest" do
    assert_empty Api::ContestPolicy.new(nil, @active_contest).visible_submission_problem_ids
    assert_empty Api::ContestPolicy.new(@member, @active_contest).visible_submission_problem_ids
  end

  test "visible_submission_problem_ids returns only the writer's own problems" do
    assert_equal [@writer_problem.id],
                 Api::ContestPolicy.new(@writer, @active_contest).visible_submission_problem_ids
  end

  test "visible_submission_problem_ids returns every problem for a contest admin" do
    assert_equal @active_contest.problems.pluck(:id).sort,
                 Api::ContestPolicy.new(contest_admin, @active_contest).visible_submission_problem_ids.sort
  end

  # --- visible_clarifications ---

  test "visible_clarifications returns only published ones for anonymous users" do
    relation = @active_contest.clarifications
    result = Api::ContestPolicy.new(nil, @active_contest).visible_clarifications(relation)

    assert_includes result, clarifications(:published_clarification)
    refute_includes result, clarifications(:unpublished_clarification)
  end

  test "visible_clarifications returns everything for a contest admin" do
    relation = @active_contest.clarifications
    result = Api::ContestPolicy.new(contest_admin, @active_contest).visible_clarifications(relation)

    assert_includes result, clarifications(:unpublished_clarification)
  end

  test "visible_clarifications includes the ones on the user's own problems" do
    relation = @active_contest.clarifications
    result = Api::ContestPolicy.new(@writer, @active_contest).visible_clarifications(relation)

    assert_includes result, clarifications(:unpublished_clarification)
  end

  test "visible_clarifications includes the user's own questions" do
    relation = @active_contest.clarifications
    result = Api::ContestPolicy.new(@member, @active_contest).visible_clarifications(relation)

    # member_user は両方の質問者
    assert_includes result, clarifications(:unpublished_clarification)
  end

  test "visible_clarification_problem_ids is empty for anonymous users" do
    assert_empty Api::ContestPolicy.new(nil, @active_contest).visible_clarification_problem_ids
  end

  test "visible_clarification_problem_ids includes nil for a contest admin" do
    ids = Api::ContestPolicy.new(contest_admin, @active_contest).visible_clarification_problem_ids
    assert_includes ids, nil
    assert_includes ids, @writer_problem.id
  end

  test "visible_clarification_problem_ids returns the writer's own problems" do
    assert_equal [@writer_problem.id],
                 Api::ContestPolicy.new(@writer, @active_contest).visible_clarification_problem_ids
  end

  # --- Scope ---

  test "scope hides private contests from non-admins" do
    private_contest = Contest.create!(
      name: 'Private Contest', slug: 'private-contest', kind: 'private', standings_mode: 1,
      start_at: 1.day.ago, end_at: 1.day.from_now, penalty_time: 5
    )

    [nil, @member, @writer].each do |user|
      refute_includes Api::ContestPolicy::Scope.new(user, Contest).resolve, private_contest
    end
    assert_includes Api::ContestPolicy::Scope.new(@admin, Contest).resolve, private_contest
  end
end
