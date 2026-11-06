# frozen_string_literal: true

# コンテストそのものに加え、コンテストに紐づくリソース（registrations /
# contest_admins / tasks / standings / manage/contests）の認可もここに集約する。
# 表示内容の決定に使う述語（include_tasks? など）も同居させている。
class Api::ContestPolicy < Api::ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    admin?
  end

  def update?
    contest_admin?
  end

  # NOTE: 現行実装はログイン済みなら誰でも実行できる（コンテスト管理者チェックが無い）。
  # 挙動を変えないためそのまま写している。
  def set_task?
    signed_in?
  end

  def rejudge?
    record.writer_or_tester?(user)
  end

  # tasks#remove_from_contest
  def remove_task?
    contest_admin?
  end

  # tasks#index
  def tasks_index?
    admin?
  end

  # submissions#index
  def submissions?
    signed_in?
  end

  # submissions#all
  def all_submissions?
    visible_submission_problem_ids.any?
  end

  def standings?
    true
  end

  def register?
    signed_in?
  end

  def register_team?
    signed_in?
  end

  def unregister?
    signed_in?
  end

  # contest_admins#create / #destroy
  def manage_admins?
    admin?
  end

  # manage/contests#index
  def manage_index?
    admin?
  end

  # manage/contests#show
  def manage_show?
    contest_admin?
  end

  # コンテスト管理者（サイト管理者を含む）か
  def contest_admin?
    record.admin?(user)
  end

  # --- 表示内容の決定に使う述語 ---

  # contests#show: 問題一覧を含めてよいか
  def include_tasks?
    record.end_at.past? ||
      (record.start_at.past? && record.registered?(user)) ||
      contest_admin?
  end

  # contests#show: 解説を出してよいか
  def show_editorial?
    record.end_at.past? || contest_admin?
  end

  # standings#index: 問題を出してよいか
  def show_problems?
    record.writer_or_tester?(user) || record.start_at.past?
  end

  # submissions#all: 提出を見せてよい問題の ID
  def visible_submission_problem_ids
    @visible_submission_problem_ids ||= build_visible_submission_problem_ids
  end

  # clarifications#index: シリアライザに渡す問題 ID
  def visible_clarification_problem_ids
    return [] unless signed_in?
    return record.problems.pluck(:id) + [nil] if contest_admin?

    writer_or_tester_problem_ids
  end

  # clarifications#index: 参照してよい clarification の絞り込み
  # @param relation [ActiveRecord::Relation]
  def visible_clarifications(relation)
    return relation.where(publish: true) unless signed_in?
    return relation if contest_admin?

    ids = writer_or_tester_problem_ids
    if ids.any?
      relation.where(publish: true)
              .or(relation.where(problem_id: ids))
              .or(relation.where(user_id: user.id))
    else
      relation.where(publish: true).or(relation.where(user_id: user.id))
    end
  end

  private

  def build_visible_submission_problem_ids
    return record.problems.pluck(:id) if record.end_at.past?
    return [] unless signed_in? && record.writer_or_tester?(user)
    return record.problems.pluck(:id) if record.official_mode || contest_admin?

    record.problems.includes(:tester_relations).filter_map do |problem|
      problem.id if problem.writer_user_id == user.id ||
        problem.tester_relations.exists?(tester_user_id: user.id, approved: true)
    end
  end

  def writer_or_tester_problem_ids
    @writer_or_tester_problem_ids ||=
      record.problems.where(writer_user_id: user.id).pluck(:id) +
      record.problems.joins(:testers).where('users.id': user.id).pluck(:id)
  end

  class Scope < Api::ApplicationPolicy::Scope
    def resolve
      admin? ? scope.all : scope.where.not(kind: 'private')
    end
  end
end
