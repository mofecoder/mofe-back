class Api::TasksController < ApplicationController
  def show
    contest = Contest.find_by!(slug: params[:contest_slug])
    task = Problem
               .includes(testcase_sets: {testcase_testcase_sets: :testcase})
               .find_by!(contest_id: contest.id, slug: params[:slug])
    render json: task, serializer: TaskSerializer
  end
end
