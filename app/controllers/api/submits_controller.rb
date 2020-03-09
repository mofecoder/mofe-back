class Api::SubmitsController < ApplicationController

  def make_path
    return Rails.root.join("submit_sources", SecureRandom.uuid)
  end

  def show
    contest_slug = params[:contest_slug]
    user_id = 1
    query = "SELECT submits.*, problems.id, problems.contest_id, contests.id, contests.slug
    FROM (submits INNER JOIN problems ON submits.problem_id = problems.id) 
    INNER JOIN contests ON problems.contest_id = contests.id
    WHERE contests.slug = :contest_slug AND submits.user_id = :user_id"

    render json: Submit.find_by_sql([query, {contest_slug: contest_slug, user_id: user_id}])
  end

  def create
    @problem = Problem.find_by!(slug: params[:task_slug])
    save_path = make_path

    @submit = Submit.new
    @submit.user_id = 1
    @submit.problem_id = @problem.id
    @submit.path = save_path
    @submit.lang = request.headers[:lang]
    @submit.status = request.headers[:status]
    @submit.execution_time = 1.0
    @submit.execution_memory = 256
    @submit.point = 114514

    @submit.save

    submited_code = request.body.read

    File.open(save_path, 'w') do |fp|
      fp.puts submited_code
    end

    redirect_to action: :show, contest_slug: params[:contest_slug]

  end


end

