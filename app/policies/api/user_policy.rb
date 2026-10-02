# frozen_string_literal: true

class Api::UserPolicy < Api::ApplicationPolicy
  def index?
    admin?
  end

  def update?
    admin? || own?
  end

  def update_admin?
    admin?
  end

  def update_rating?
    admin?
  end

  def generate_writer_request_code?
    admin? || own?
  end

  private

  def own?
    signed_in? && record.is_a?(User) && record.id == user.id
  end
end
