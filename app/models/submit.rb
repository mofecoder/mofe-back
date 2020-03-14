class Submit < ApplicationRecord
  belongs_to :problem
  has_many :testcase_results

  scope :user_id, -> (user_id) { where(user_id: user_id) }

  class << self
    def search_by_user_id(user_id)
      user_id(user_id)
    end
  end
end
