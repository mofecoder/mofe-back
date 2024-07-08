class ChangeTeamRegistrationsOpenRegistrationToNotNull < ActiveRecord::Migration[6.1]
  def change
    change_column_null :team_registrations, :open_registration, false, 0
  end
end
