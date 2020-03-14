class TestcaseResult < ApplicationRecord
  belongs_to :submit
  belongs_to :testcase
end