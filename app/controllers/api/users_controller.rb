require 'net/http'
require 'json'

class Api::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin_user!, only: [:index, :update_admin, :update_rating]

  def index
    render json: User.all.as_json(only: [:id, :name, :role, :writer_request_code, :created_at])
  end

  def update_admin
    user = User.find(params[:user_id])
    user.update!(user_update_admin_param)
  end

  def update
    if !current_user.admin? && User.find(params[:id]).id != current_user.id
      render_403
      return
    end

    param = user_update_param
    rating = nil

    if param[:atcoder_id].present?
      begin
        rating = get_rating(param[:atcoder_id])
      end
    end

    param[:atcoder_rating] = rating
    current_user.update!(param)
  end

  def update_rating
    render status: :no_content
    users = User.where.not(atcoder_id: nil)
    users.each do |user|
      user.update!(atcoder_rating: get_rating(user.atcoder_id))
      sleep(2)
    end
  end

  def generate_writer_request_code
    user = User.find(params[:id])
    unless current_user.admin?
      if user.id != current_user.id
        render_403
        return
      end
      if user.writer_request_code.present?
        render json: { error: 'Writer Request が無効です' }, status: :conflict
      end
    end
    user.writer_request_code = SecureRandom.uuid
    user.save!
  end

  private

  def user_update_param
    params.require(:user).permit(:atcoder_id)
  end

  def user_update_admin_param
    params.require(:user).permit(:atcoder_id, :role)
  end

  def get_rating(atcoder_id)
    res = Net::HTTP.get(
      URI.parse("https://atcoder.jp/users/#{atcoder_id}/history/json")
    )
    # @type [Array[Hash]]
    obj = JSON.parse(res)
    obj.present? ? obj.last['NewRating'] : 0
  end
end
