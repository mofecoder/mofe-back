# frozen_string_literal: true

class Api::PostPolicy < Api::ApplicationPolicy
  def index?
    true
  end

  def show?
    admin? || record.public_status != 'private'
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  class Scope < Api::ApplicationPolicy::Scope
    def resolve
      admin? ? scope.all : scope.where(public_status: 'public')
    end
  end
end
