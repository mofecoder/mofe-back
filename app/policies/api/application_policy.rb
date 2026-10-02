# frozen_string_literal: true

# v1 API (`app/controllers/api/`) 用のポリシー基底クラス。
#
# v1 には未ログインでも到達できるエンドポイントが多いため、v4 の ProblemPolicy の
# ように nil user で Pundit::NotAuthorizedError を raise せず、各ポリシー側で
# nil を扱う。呼び出しは `authorize [:api, record]` / `policy_scope([:api, Model])`。
class Api::ApplicationPolicy < ApplicationPolicy
  private

  def signed_in?
    user.present?
  end

  # サイト全体の管理者（role: admin）か
  def admin?
    user.present? && user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    private

    def admin?
      user.present? && user.admin?
    end
  end
end
