class Api::AllsController < ApplicationController
  def show
    contest_slug = params[:contest_slug]
    render json: Submit.joins(problem: :contest)
                  .select("submits.*, problems.id, problems.contest_id, contests.id, contests.slug")
                  .where("contests.slug = ?", contest_slug)
  end
end

