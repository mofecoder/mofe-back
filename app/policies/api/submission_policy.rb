# frozen_string_literal: true

class Api::SubmissionPolicy < Api::ApplicationPolicy
  def show?
    return true if signed_in? && (admin_or_writer? || record.user_id == user.id || teammate?)

    record.problem.contest.end_at.past? && record.public
  end

  def rejudge?
    return false unless signed_in?

    user.contest_admin?(record.problem.contest_id) || rejudge_as_problem_member?
  end

  # 問題の writer、または承認済み tester か（ロード済みの tester_relations を使うので SQL を発行しない）
  def rejudge_as_problem_member?
    return false unless signed_in?

    problem = record.problem
    problem.writer_user_id == user.id ||
      problem.tester_relations.any? { |r| r.tester_user_id == user.id && r.approved }
  end

  # デバッグ提出の出力のうち、見られるストリームの一覧（S7b）。
  # 'all'（デバッグ提出）は問題の admin_or_writer? に当たる人だけが全部見られる（提出者本人に限らない）。
  # 将来 'user'（提出の stdout / stderr だけを一般のユーザーにも見せる）を足すときは、ここに1行足す。
  # @return [Array<String>]
  def output_streams
    case record.output_capture
    when 'all'
      admin_or_writer? ? TestcaseResult::OUTPUT_STREAMS : []
    else
      []
    end
  end

  def toggle_published?
    record.problem.check_admin_or_writer_or_tester(user)
  end

  private

  # 同じチームのメンバーの提出か
  def teammate?
    record.problem.contest.teammate_user_ids(user).include?(record.user_id)
  end

  def admin_or_writer?
    Api::ProblemPolicy.new(user, record.problem).admin_or_writer?
  end
end
