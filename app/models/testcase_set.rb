class TestcaseSet < ApplicationRecord
  has_many :testcase_testcase_sets, dependent: :destroy
  has_many :testcases, through: :testcase_testcase_sets
end
