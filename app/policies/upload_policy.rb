class UploadPolicy < ApplicationPolicy
  def initialize(user, record)
    raise Pundit::NotAuthorizedError unless user
    super
  end

  def index?
    uploader?
  end

  def create?
    uploader?
  end

  def complete?
    uploader? && owner?
  end

  # admin は他人の画像も削除できる
  def destroy?
    user.admin? || owner?
  end

  private

  def uploader?
    user.admin? || user.writer?
  end

  def owner?
    record.is_a?(Upload) && record.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    # 一覧は自分のアップロードだけ
    def resolve
      scope.where(user: user)
    end
  end
end
