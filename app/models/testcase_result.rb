class TestcaseResult < ApplicationRecord
  belongs_to :submit, dependent: :destroy
  belongs_to :testcase, dependent: :destroy
end
