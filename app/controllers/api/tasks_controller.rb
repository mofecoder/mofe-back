class Api::TasksController < Api::ApplicationController
  before_action :authenticate_user!, only: [:index, :remove_from_contest, :move]

  def index
    # コンテストを引く前に認可する（未知の slug でも 403 を返す現行挙動を維持）
    authorize [:api, Contest], :tasks_index?

    contest = Contest.find_by!(slug: params[:contest_slug])
    tasks = contest.problems.includes(:writer_user)
    render json: tasks
  end

  def show
    # @type [Contest]
    contest = Contest.find_by!(slug: params[:contest_slug])
    task = Problem
           .includes(testcase_sets: {testcase_testcase_sets: :testcase})
           .find_by!(contest_id: contest.id, slug: params[:slug])

    authorize [:api, task], :show_task?

    render json: task, serializer: TaskSerializer
  end

  def remove_from_contest
    contest = Contest.find_by!(slug: params[:contest_slug])
    authorize [:api, contest], :remove_task?

    task = Problem.find_by!(contest_id: contest.id, slug: params[:task_slug])
    task.contest_id = nil
    task.slug = nil
    task.position = nil
    task.save
  end

  # 問題のコンテスト内の位置を変更する。移動先に別の問題があれば入れ替える。
  # slug も "<contest_slug>_<位置の小文字>" に合わせて変更する。
  def move
    contest = Contest.find_by!(slug: params[:contest_slug])
    authorize [:api, contest], :move_task?

    position = params[:position]
    if position.blank?
      render_api_error("パラメータ 'position' が必要です。", status: :bad_request)
      return
    end

    task = Problem.find_by!(contest_id: contest.id, slug: params[:task_slug])
    return head :no_content if task.position == position

    old_position = task.position
    other = contest.problems.where.not(id: task.id).find_by(position: position)

    saved = false
    ActiveRecord::Base.transaction do
      if other
        # slug のユニーク制約に引っかからないよう、相手の slug をいったん退避する
        other.slug = "#{contest.slug}_tmp_#{SecureRandom.hex(4)}"
        raise ActiveRecord::Rollback unless other.save
      end

      task.position = position
      task.slug = "#{contest.slug}_#{position.downcase}"
      raise ActiveRecord::Rollback unless task.save

      if other
        other.position = old_position
        other.slug = "#{contest.slug}_#{old_position.downcase}"
        raise ActiveRecord::Rollback unless other.save
      end

      saved = true
    end

    if saved
      head :no_content
    else
      messages = (task.errors.full_messages + (other&.errors&.full_messages || [])).uniq
      details = task.errors.to_hash.merge(other&.errors&.to_hash || {}) { |_, a, b| (a + b).uniq }
      render_api_error(messages.join("\n"), status: :unprocessable_content, details: details)
    end
  end
end
