class Api::TesterRelationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_problem

  def create
    user = User.find_by(name: params[:user_name])

    unless user
      render json: {
          error: '指定されたユーザ名のユーザは存在しません。',
      }, status: :not_found
      return
    end

    if @problem.tester_relations.where(tester_user_id: user.id).exists?
      render json: {
          error: '指定されたユーザは既にテスターとして追加されています。'
      }, status: :bad_request
      return
    end

    # TODO: approve の実装
    @problem.tester_relations.create(tester_user_id: user.id, approved: true)

    render status: :created
  end

  def destroy
    unless current_user.admin? || @problem.writer_user_id == current_user.id
      render_403
    end

    user = User.find_by!(name: params[:user_name])
    @problem.tester_relations.find_by!(tester_user_id: user.id).destroy
  end

  private

  def set_problem
    @problem = Problem.find(params[:problem_id])
    unless current_user.admin? || problem.writer_user_id == current_user.id
      render_403
    end
  end
end
