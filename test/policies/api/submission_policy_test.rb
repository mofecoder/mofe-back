# frozen_string_literal: true

require 'test_helper'

class Api::SubmissionPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @member_submission = submissions(:member_submission)  # member / writer_problem / public
    @writer_submission = submissions(:writer_submission)  # writer / writer_problem / 非公開
    @admin_problem = problems(:admin_problem)             # ended_contest
  end

  def create_user(name)
    User.create!(
      name: name, email: "#{name}@example.com",
      password: 'password', password_confirmation: 'password',
      provider: 'email', uid: "#{name}@example.com", role: 'member'
    )
  end

  def ended_contest_submission(public:)
    Submission.create!(
      user: @member, problem: @admin_problem, path: '/submissions/x',
      status: 'AC', point: 100, lang: 'cpp', public: public
    )
  end

  # --- 未ログイン ---

  test "does not raise for a nil user" do
    assert_nothing_raised do
      Api::SubmissionPolicy.new(nil, @member_submission).show?
      Api::SubmissionPolicy.new(nil, @member_submission).rejudge?
      Api::SubmissionPolicy.new(nil, @member_submission).toggle_published?
    end
  end

  # --- show? ---

  test "show? permits the submitter" do
    assert Api::SubmissionPolicy.new(@member, @member_submission).show?
  end

  test "show? denies a member looking at another user's private submission" do
    refute Api::SubmissionPolicy.new(@member, @writer_submission).show?
  end

  test "show? permits the problem writer and admins" do
    assert Api::SubmissionPolicy.new(@writer, @member_submission).show?
    assert Api::SubmissionPolicy.new(@admin, @member_submission).show?
  end

  test "show? permits a contest admin for another user's private submission" do
    user = create_user('show_contest_admin')
    ContestAdmin.create!(user: user, contest: @writer_submission.problem.contest)

    assert Api::SubmissionPolicy.new(user, @writer_submission).show?
  end

  test "show? denies anonymous users while the contest is running" do
    refute Api::SubmissionPolicy.new(nil, @member_submission).show?
  end

  test "show? permits anonymous users for a public submission once the contest has ended" do
    assert Api::SubmissionPolicy.new(nil, ended_contest_submission(public: true)).show?
  end

  test "show? denies anonymous users for a private submission even after the contest" do
    refute Api::SubmissionPolicy.new(nil, ended_contest_submission(public: false)).show?
  end

  # --- rejudge? ---

  test "rejudge? permits admins and the problem writer" do
    assert Api::SubmissionPolicy.new(@admin, @member_submission).rejudge?
    assert Api::SubmissionPolicy.new(@writer, @member_submission).rejudge?
  end

  test "rejudge? denies members and anonymous users" do
    refute Api::SubmissionPolicy.new(@member, @member_submission).rejudge?
    refute Api::SubmissionPolicy.new(nil, @member_submission).rejudge?
  end

  # NOTE: rejudge だけ approved を見ていない（現行挙動をそのまま維持している）
  test "rejudge? permits an unapproved tester" do
    tester = create_user('rejudge_tester')
    TesterRelation.create!(problem: @member_submission.problem, user: tester, approved: false)

    assert Api::SubmissionPolicy.new(tester, @member_submission).rejudge?
  end

  # --- toggle_published? ---

  test "toggle_published? permits the problem writer and admins only" do
    assert Api::SubmissionPolicy.new(@writer, @member_submission).toggle_published?
    assert Api::SubmissionPolicy.new(@admin, @member_submission).toggle_published?
    refute Api::SubmissionPolicy.new(@member, @member_submission).toggle_published?
    refute Api::SubmissionPolicy.new(nil, @member_submission).toggle_published?
  end
end
