class Submit < ApplicationRecord
  belongs_to :problem
  belongs_to :user
  has_many :testcase_results, -> { order(:testcase_id) }
  has_many :testcase_results_in_contest,
           -> { order(:status) },
           class_name: 'TestcaseResult'

  scope :user_id, -> (user_id) { where(user_id: user_id) }

  class << self
    def search_by_user_id(user_id)
      user_id(user_id)
    end
  end
end
