class Clarification < ApplicationRecord
  acts_as_paranoid

  belongs_to :contest
  belongs_to :problem, optional: true
  belongs_to :user
end
