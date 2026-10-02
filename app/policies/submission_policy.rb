class SubmissionPolicy < ApplicationPolicy
  attr_reader :user, :submission, :contest

  def initialize(user, submission, contest)
    @contest = contest
    super(user, submission)
  end

  def index?
    @user.present? && @contest.registered?(@user)
  end

  def all?
    return true if contest.ended?
    contest.writer_or_tester?(@user)
  end

  def show?
    submission.contest.admin?(@user) ||
      submission.user == @user ||
      submission.problem.writer_user == @user ||
      submission.problem.tester?(@user) ||
      (submission.contest.ended? && submission.public?)
  end

  def create?
    submission.problem.has_permission?(@user)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve


    end
  end
end
