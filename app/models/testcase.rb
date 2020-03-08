class Testcase < ApplicationRecord
  has_many :testcase_testcase_sets
  has_many :testcase_sets, through: :testcase_testcase_sets
end
