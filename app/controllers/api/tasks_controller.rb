class Api::TasksController < Api::ApplicationController
  before_action :authenticate_user!, only: [:index, :remove_from_contest]

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
end
