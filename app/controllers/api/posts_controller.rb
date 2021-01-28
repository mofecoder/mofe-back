class Api::PostsController < ApplicationController
  def index
    posts = Post.all

    unless current_user&.admin?
      posts.where!(public_status: 'public')
    end

    puts params[:count].present?
    if params[:count].present?
      posts.limit!(params[:count])
    end

    render json: posts
  end

  def show
    post = Post.find(params[:id])

    if !current_user&.admin? && post.public_status == 'private'
      render json: { error: '権限がありません' }, status: :forbidden
      return
    end

    render json: post
  end

  def create
    post = Post.new(post_param)
    if post.save
      render json: post, status: :created
    else
      render json: { error: post.errors }, status: :bad_request
    end
  end

  def update
    post = Post.find(params[:id])
    unless post.update(post_param)
      render json: { error: post.errors }, status: :bad_request
    end
  end

  def destroy
    post = Post.find(params[:id])
    unless post.destroy
      render json: { error: post.errors }, status: :bad_request
    end
  end

  private

  def post_param
    params.require(:post).permit(:title, :content, :public_status)
  end
end
