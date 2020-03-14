class Api::ContestsController < ApplicationController
  before_action :set_contest, except: [:index]

  def index
    render json: Contest.all
                     .includes(:problems)
                     .as_json(only: [:slug, :name, :start_at, :end_at])
  end

  def show
    render json: @contest, serializer: ContestDetailSerializer
  end

  private
  def set_contest
    @contest = Contest.find_by!(slug: params[:slug])
  end
end
