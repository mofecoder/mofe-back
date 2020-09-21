class Problem < ApplicationRecord
  belongs_to :contest, optional: true
  belongs_to :writer_user, class_name: 'User'
  has_many :testcases
  has_many :testcase_sets
  has_many :submits
  has_many :tester_relations, dependent: :destroy
  has_many :testers, through: :tester_relations, source: :user
  has_many :clarifications

  validates :slug, uniqueness: true, allow_nil: true

  def samples
    set = testcase_sets.find_by(problem_id: id, is_sample: 1)
    return set unless set
    set
      .testcases
      .includes(:problem)
      .order(:id)
      .map do |m| {
          input: m.input_data(true),
          output: m.output_data(true),
          explanation: m.explanation
      }
    end
  end

  def to_param
    slug
  end
end
