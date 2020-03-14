class TestcaseSet < ApplicationRecord
  has_many :testcase_testcase_sets
  has_many :testcases, through: :testcase_testcase_sets
  has_many :testcase_results
end
