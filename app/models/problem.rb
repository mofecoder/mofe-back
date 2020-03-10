class Problem < ApplicationRecord
  belongs_to :contest
  has_many :testcase_sets
  has_many :submits

  def samples
    testcase_sets.find_by!(problem_id: id, is_sample: 1).testcases.map do |m|
      {
          input: m.input,
          output: m.output,
          explanation: m.explanation
      }
    end
  end

  def to_param
    slug
  end
end
