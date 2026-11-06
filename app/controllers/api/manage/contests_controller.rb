class Api::Manage::ContestsController < Api::ApplicationController
  before_action :authenticate_user!

  def index
    authorize [:api, Contest], :manage_index?

    render json: Contest.all.order(id: :desc).as_json(only: [:slug, :name, :kind, :start_at, :end_at])
  end

  def show
    # @type [Contest]
    contest = Contest.preload(problems: [:writer_user, :testcase_sets]).find_by!(slug: params[:slug])
    authorize [:api, contest], :manage_show?

    render json: contest, serializer: Manage::ContestSerializer, show_editorial: true
  end
end
