class TestcaseSet < ApplicationRecord
  has_many :testcase_testcase_sets, dependent: :destroy
  has_many :testcases, through: :testcase_testcase_sets

  enum aggregate_type: { all: 0, sum: 1, max: 2, min: 3 }, _prefix: true
end
