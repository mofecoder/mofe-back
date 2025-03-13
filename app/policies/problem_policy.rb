class ProblemPolicy < ApplicationPolicy
  attr_reader :user, :problem

  def initialize(user, problem)
    raise Pundit::NotAuthorizedError unless user
    super
  end

  def index?
    true
  end

  def show?
    user.admin? ||
      user.contest_admin?(record.contest) ||
      user == record.writer_user ||
      record.tester?(user)
  end

  def create?
    index? && (user.admin? || user.writer?)
  end

  def update?
    user.admin? ||
      user.contest_admin?(record.contest) ||
      user == record.writer_user
  end

  def destroy?
    user.admin?
  end


  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(writer_user: user)
      end
    end
  end
end
