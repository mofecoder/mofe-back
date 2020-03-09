class Api::SubmitsController < ApplicationController
  def show
    user_id = 1
    render json: Submit.find_by!(user_id: user_id)
  end

  def create
    @problem = Problem.find_by!(slug: params[:task_slug])

    @submit = Submit.new
    @submit.user_id = 1
    @submit.problem_id = @problem.id
    @submit.path = "hoge"
    @submit.lang = request.headers[:lang]
    @submit.status = request.headers[:status]
    @submit.execution_time = 1.0
    @submit.execution_memory = 256
    @submit.point = 114514

    @submit.save

    submited_code = request.body

  end

  def make_path

  end

end
