# frozen_string_literal: true

class Api::SubmissionPolicy < Api::ApplicationPolicy
  def show?
    return true if signed_in? && (admin_or_writer? || record.user_id == user.id)

    record.problem.contest.end_at.past? && record.public
  end

  def rejudge?
    return false unless signed_in?

    user.contest_admin?(record.problem.contest_id) || rejudge_as_problem_member?
  end

  # 問題の writer、または承認済み tester か（ロード済みの tester_relations を使うので SQL を発行しない）
  def rejudge_as_problem_member?
    return false unless signed_in?

    problem = record.problem
    problem.writer_user_id == user.id ||
      problem.tester_relations.any? { |r| r.tester_user_id == user.id && r.approved }
  end

  def toggle_published?
    record.problem.check_admin_or_writer_or_tester(user)
  end

  private

  def admin_or_writer?
    Api::ProblemPolicy.new(user, record.problem).admin_or_writer?
  end
end
