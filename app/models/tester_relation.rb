class TesterRelation < ApplicationRecord
  belongs_to :user, class_name: 'User', foreign_key: :tester_user_id
  belongs_to :problem
end
