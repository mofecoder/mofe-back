class Clarification < ApplicationRecord
  belongs_to :contest
  belongs_to :problem, optional: true
  belongs_to :user
end
