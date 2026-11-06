# frozen_string_literal: true

class Api::ClarificationPolicy < Api::ApplicationPolicy
  # 絞り込みは Api::ContestPolicy#visible_clarifications が行う
  def index?
    true
  end

  def create?
    signed_in?
  end

  def show?
    return false unless signed_in?
    return true if record.contest.admin?(user)
    return false if record.problem.blank?

    record.problem.writer_user_id == user.id ||
      record.problem.tester_ids.include?(user.id)
  end

  def update?
    show?
  end
end
