class Problem < ApplicationRecord
  belongs_to :contest, optional: true
  belongs_to :writer_user, class_name: 'User'
  has_many :testcases
  has_many :testcase_sets
  has_many :submissions
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

  def has_permission?(user)
    #@type [Contest]
    contest = self.contest
    return true if contest.end_at.past?
    return true if contest.start_at.past? && contest.registered?(user)
    user.present? && (
      user.admin? ||
      writer_user_id == user.id ||
      tester_relations.exists?(tester_user_id: user.id, approved: true) ||
      (contest.is_writer_or_tester(user) && (contest.official_mode || contest.start_at.past?))
    )
  end

  def to_param
    slug
  end
end
