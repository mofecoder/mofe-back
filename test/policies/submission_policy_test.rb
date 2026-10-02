# frozen_string_literal: true

require 'test_helper'

class SubmissionPolicyTest < ActiveSupport::TestCase
  def setup
    @admin = users(:admin_user)
    @writer = users(:writer_user)
    @member = users(:member_user)
    @member_submission = submissions(:member_submission)
    @active_contest = contests(:active_contest)
    @ended_contest = contests(:ended_contest)
  end

  # NOTE: show? は submission.contest を参照しているが、
  # Submission モデルに contest アソシエーションが存在しないためテスト不可。
  # Submission に delegate :contest, to: :problem を追加するか、
  # ポリシー内で submission.problem.contest を使うよう修正が必要。

  # --- all? ---

  test "all? permits when contest has ended" do
    policy = SubmissionPolicy.new(@member, @member_submission, @ended_contest)
    assert policy.all?
  end

  test "all? denies member on active contest" do
    policy = SubmissionPolicy.new(@member, @member_submission, @active_contest)
    refute policy.all?
  end

  test "all? permits writer_or_tester on active contest" do
    # writer_user is the problem writer, which makes them a writer_or_tester for the contest
    policy = SubmissionPolicy.new(@writer, @member_submission, @active_contest)
    assert policy.all?
  end
end
