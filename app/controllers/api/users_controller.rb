require 'net/http'
require 'json'

class Api::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin_user!, only: [:update_rating]

  def update
    if !current_user.admin? && params[:id] != current_user.id
      render_403
      return
    end

    param = user_update_param
    rating = 0

    if atc.present?
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

  private

  def user_update_param
    params.require(:user).permit(:atcoder_id)
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
