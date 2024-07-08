class TeamRegistrationUser < ApplicationRecord
  belongs_to :team_registration
  belongs_to :user
end
