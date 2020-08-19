class TestcaseTestcaseSet < ApplicationRecord
  belongs_to :testcase, dependent: :destroy
  belongs_to :testcase_set, dependent: :destroy
end
