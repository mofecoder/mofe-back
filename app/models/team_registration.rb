class TeamRegistration < ApplicationRecord
  belongs_to :contest
  has_many :team_registration_users, dependent: :destroy
end
