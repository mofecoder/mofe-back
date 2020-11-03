class Api::TasksController < ApplicationController
  before_action :authenticate_user!, only: [:index, :remove_from_contest]
  before_action :authenticate_admin_user!, only: [:index, :remove_from_contest]

  def index
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

    ok = true

    if contest.end_at.future?
      ok = contest.start_at.past? && contest.registered?(current_user)

      if !ok && user_signed_in? && (
        current_user.admin? ||
        task.writer_user_id == current_user.id ||
        task.tester_relations.exists?(tester_user_id: current_user.id, approved: true)
      )
        ok = true
      end
    end

    if ok
      render json: task, serializer: TaskSerializer
    else
      render_403
    end
  end

  def remove_from_contest
    contest = Contest.find_by!(slug: params[:contest_slug])
    task = Problem.find_by!(contest_id: contest.id, slug: params[:task_slug])
    task.contest_id = nil
    task.slug = nil
    task.position = nil
    task.save
  end
end
