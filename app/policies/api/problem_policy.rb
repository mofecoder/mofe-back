# frozen_string_literal: true

# 問題そのものに加え、問題に紐づくリソース（testcases / testcase_sets /
# tester_relations / tasks#show）の認可もここに集約する。
class Api::ProblemPolicy < Api::ApplicationPolicy
  # problems#index / #create（旧 authenticate_writer!）
  def index?
    admin? || writer?
  end

  def create?
    index?
  end

  def show?
    return false unless signed_in?

    contest_admin? ||
      record.writer_user_id == user.id ||
      record.tester?(user)
  end

  def update?
    return false unless signed_in?

    contest_admin? || record.writer_user_id == user.id
  end

  def download_checker?
    update?
  end

  def update_checker?
    update?
  end

  # testcases#* / testcase_sets#*
  def manage_testcases?
    return false unless signed_in?

    contest_admin? || (writer? && record.writer_user_id == user.id)
  end

  # tester_relations#create / #destroy
  def manage_testers?
    update?
  end

  # tasks#show（未ログインでも到達する）
  def show_task?
    record.has_permission?(user)
  end

  # submissions#create
  def submit?
    record.has_permission?(user)
  end

  # contests#set_task で「他のユーザの問題」を弾く判定
  def add_to_contest?
    return false unless signed_in?

    !(writer? && record.writer_user_id != user.id)
  end

  # manage/problems#unset_problems
  def unset_problems?
    signed_in? && !user.member?
  end

  # テストケース評価情報（結果・名前・score）を見られる人の定義。
  # submissions#show / #create（旧 Api::SubmissionsController#is_admin_or_writer?）
  def admin_or_writer?
    return false unless signed_in?

    contest_admin? ||
      record.writer_user_id == user.id ||
      record.tester?(user) ||
      (record.contest.present? && record.contest.writer_or_tester?(user) && record.contest.official_mode)
  end

  private

  def writer?
    signed_in? && user.writer?
  end

  # User#contest_admin? は nil / 未所属コンテストを false として扱う
  def contest_admin?
    user.contest_admin?(record.contest_id)
  end

  class Scope < Api::ApplicationPolicy::Scope
    def resolve
      admin? ? scope.all : scope.where(writer_user_id: user&.id)
    end
  end
end
