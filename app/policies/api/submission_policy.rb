# frozen_string_literal: true

class Api::SubmissionPolicy < Api::ApplicationPolicy
  def show?
    return true if signed_in? && (admin_or_writer? || record.user_id == user.id)

    record.problem.contest.end_at.past? && record.public
  end

  def rejudge?
    return false unless signed_in?

    problem = record.problem
    user.contest_admin?(problem.contest_id) ||
      problem.writer_user_id == user.id ||
      problem.tester_relations.exists?(tester_user_id: user.id)
  end

  def toggle_published?
    record.problem.check_admin_or_writer_or_tester(user)
  end

  private

  def admin_or_writer?
    Api::ProblemPolicy.new(user, record.problem).admin_or_writer?
  end
end
