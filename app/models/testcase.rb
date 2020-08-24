class Testcase < ApplicationRecord
  acts_as_paranoid
  has_many :testcase_testcase_sets
  has_many :testcase_sets, through: :testcase_testcase_sets, dependent: destroy
end
