class Problem < ApplicationRecord
  belongs_to :contest, optional: true
  has_many :testcase_sets
  has_many :submits

  validates :slug, uniqueness: true, allow_nil: true

  def samples
    testcase_sets.find_by(problem_id: id, is_sample: 1)&.testcases&.map do |m|
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
