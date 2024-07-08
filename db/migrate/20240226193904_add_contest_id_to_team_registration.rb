class AddContestIdToTeamRegistration < ActiveRecord::Migration[6.1]
  def change
    add_reference :team_registrations, :contest, foreign_key: true, null: false, after: :id
  end
end
