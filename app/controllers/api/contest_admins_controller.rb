class Api::ContestAdminsController < Api::ApplicationController
  before_action :authenticate_user!
  before_action :authorize_manage_admins!
  before_action :set_contest

  def create
    user = User.find_by(name: params[:user_name])

    unless user
      render json: {
        error: '指定されたユーザ名のユーザは存在しません。',
      }, status: :not_found
      return
    end

    if @contest.contest_admins.where(user_id: user.id).exists?
      render json: {
        error: '指定されたユーザは既にコンテスト管理者として追加されています。'
      }, status: :bad_request
      return
    end

    ContestAdmin.create(contest_id: @contest.id, user_id: user.id)

    render status: :created
  end

  def destroy
    user = User.find_by!(name: params[:user_name])
    @contest.contest_admins.find_by!(user_id: user.id).discard
  end

  private

  # コンテストを引く前に認可する（未知の slug でも 403 を返す現行挙動を維持）
  def authorize_manage_admins!
    authorize [:api, Contest], :manage_admins?
  end

  def set_contest
    @contest = Contest.find_by!(slug: params[:contest_slug])
  end
end
