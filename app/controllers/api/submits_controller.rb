class Api::SubmitsController < ApplicationController
  before_action :authenticate_user!, except: [:all]

  def me
    if current_user.nil?
      render status: 401
    end
    contest_slug = params[:contest_slug]
    user_id = current_user.id
    # :contest_slugからsubmitを抽出する
    my_submits = Submit.preload(:problem, :user)
                     .joins(problem: :contest)
                     .where("contests.slug = ?", contest_slug)
                     .search_by_user_id(user_id)
                     .order(created_at: :desc)
    render json: my_submits
  end

  def all
    contest_slug = params[:contest_slug]
    all_submits = Submit.preload(:problem)
                      .joins(problem: :contest)
                      .where("contests.slug = ?", contest_slug)
                      .order(created_at: :desc)
    
    render json: all_submits
  end


  def create
    if current_user.nil?
      render status: 401
    end
    @problem = Problem.find_by!(slug: params[:task_slug])
    save_path = make_path

    # ちゃんとバリデーションした方が良さそう？
    @submit = current_user.submits.new
    @submit.problem_id = @problem.id
    @submit.path = save_path
    @submit.lang = request.headers[:lang]
    @submit.status = request.headers[:status]
    @submit.execution_time = 1.0
    @submit.execution_memory = 256
    @submit.point = 200

    @submit.save

    submitted_code = request.body.read

    File.open(save_path, 'w') do |fp|
      fp.puts submitted_code
    end
  end

  private

  # pathを生やす
  def make_path
    "submit_sources/#{SecureRandom.uuid}"
  end
end
