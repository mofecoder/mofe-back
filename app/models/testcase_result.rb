class TestcaseResult < ApplicationRecord
  belongs_to :submission
  belongs_to :testcase
end
