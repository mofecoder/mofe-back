class Api::Manage::ContestsController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin_user!, only: [:index]

  def index
    render json: Contest.all.order(id: :desc).as_json(only: [:slug, :name, :kind, :start_at, :end_at])
  end

  def show
    # @type [Contest]
    contest = Contest.find_by!(slug: params[:slug])
    unless current_user.admin_for_contest?(contest.id)
      render_403
      return
    end
    render json: contest, serializer: Manage::ContestSerializer, show_editorial: true
  end
end
