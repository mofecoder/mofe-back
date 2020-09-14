class Api::Manage::ContestsController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin_user!

  def index
    render json: Contest.all.order(id: :desc).as_json(only: [:slug, :name, :start_at, :end_at])
  end

  def show
    render json: Contest.find_by!(slug: params[:slug]), serializer: Manage::ContestSerializer
  end
end
