class Api::TasksController < ApplicationController
  before_action :authenticate_user!, only: [:index, :remove_from_contest]
  before_action :authenticate_admin_user!, only: [:index, :remove_from_contest]

  def index
    contest = Contest.find_by!(slug: params[:contest_slug])
    tasks = contest.problems.includes(:writer_user)
    render json: tasks
  end

  def show
    contest = Contest.find_by!(slug: params[:contest_slug])
    task = Problem
               .includes(testcase_sets: {testcase_testcase_sets: :testcase})
               .find_by!(contest_id: contest.id, slug: params[:slug])
    render json: task, serializer: TaskSerializer
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
