class Api::AllsController < ApplicationController
  def show
    contest_slug = params[:contest_slug]
    query = "SELECT submits.*, problems.id, problems.contest_id, contests.id, contests.slug
    FROM (submits INNER JOIN problems ON submits.problem_id = problems.id) 
    INNER JOIN contests ON problems.contest_id = contests.id
    WHERE contests.slug = :contest_slug;"

    render json: Submit.find_by_sql([query, {contest_slug: contest_slug}])
  end
end
