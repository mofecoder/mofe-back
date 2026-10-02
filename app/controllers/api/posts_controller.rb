class Api::PostsController < Api::ApplicationController
  before_action :authenticate_user!, only: [:create, :update, :destroy]

  def index
    authorize [:api, Post]
    posts = policy_scope([:api, Post]).order(id: :desc)

    if params[:count].present?
      posts.limit!(params[:count])
    end

    render json: posts
  end

  def show
    post = Post.find(params[:id])
    authorize [:api, post]

    render json: post
  end

  def create
    authorize [:api, Post]

    post = Post.new(post_param)
    if post.save
      render json: post, status: :created
    else
      render json: { error: post.errors }, status: :bad_request
    end
  end

  def update
    post = Post.find(params[:id])
    authorize [:api, post]

    unless post.update(post_param)
      render json: { error: post.errors }, status: :bad_request
    end
  end

  def destroy
    post = Post.find(params[:id])
    authorize [:api, post]

    unless post.discard
      render json: { error: post.errors }, status: :bad_request
    end
  end

  private

  def post_param
    params.require(:post).permit(:title, :content, :public_status)
  end
end
