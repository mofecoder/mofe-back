class Api::SubmitsController < ApplicationController
  before_action :authenticate_user!, except: [:all, :show]

  def index
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

  def show
    submit = Submit.includes(:testcase_results).find(params[:id])
    contest = submit.problem.contest

    if contest.slug != params[:contest_slug]
      render status: 404
      return
    end

    if current_user.nil? || (!current_user.admin? && submit.user_id != current_user.id)
      unless contest.end_at.past?
        render json: {
            error: 'この提出は非公開です'
        }, status: :forbidden
        return
      end
    end


    render json: submit, serializer: SubmitDetailSerializer
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
    @submit.status = 'WJ'

    source = request.body.read
    Utils::GoogleCloudStorageClient::upload_source(save_path, source)
    @submit.save!
  end

  private

  # pathを生やす
  def make_path
    "submit_sources/#{SecureRandom.uuid}"
  end
end
