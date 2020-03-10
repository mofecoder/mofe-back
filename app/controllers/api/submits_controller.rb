class Api::SubmitsController < ApplicationController

  def me
    contest_slug = params[:contest_slug]
    user_id = 1
    # :contest_slugからsubmitを抽出する
    my_submits = Submit.joins(problem: :contest)
                  .select("submits.*, problems.*, contests.id, contests.slug AS contest_slug")
                  .where("contests.slug = ?", contest_slug)
                  .search_by_user_id(user_id)
    
    render json: my_submits
  end

  def all
    contest_slug = params[:contest_slug]
    all_submits = Submit.joins(problem: :contest)
                  .select("submits.*, problems.*, contests.id, contests.slug AS contest_slug")
                  .where("contests.slug = ?", contest_slug)
    
    render json: all_submits
  end
  

  def create
    @problem = Problem.find_by!(slug: params[:task_slug])
    save_path = make_path

    # ちゃんとバリデーションした方が良さそう？
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

    submitted_code = request.body.read

    File.open(save_path, 'w') do |fp|
      fp.puts submitted_code
    end
  end

  private

  # pathを生やす
  def make_path
    Rails.root.join("submit_sources", SecureRandom.uuid)
  end
end

