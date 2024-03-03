class ContestAdmin < ApplicationRecord
  belongs_to :user, class_name: 'User'
  belongs_to :contest
end
