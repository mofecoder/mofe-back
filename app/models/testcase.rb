class Testcase < ApplicationRecord
  acts_as_paranoid
  belongs_to :problem
  has_many :testcase_testcase_sets, dependent: :destroy
  has_many :testcase_results, dependent: :destroy
  has_many :testcase_sets, through: :testcase_testcase_sets
end
