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
  validates :submission_limit_1, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :submission_limit_2, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def samples
    set = testcase_sets.find_by(problem_id: id, is_sample: 1)
    return set unless set

    set.testcases
      .includes(:problem)
      .order(:name)
      .map do |m| {
          input: m.input_data(true),
          output: m.output_data(true),
          explanation: m.explanation
      }
    end
  end

  # @param [User] user
  def has_permission?(user)
    #@type [Contest]
    contest = self.contest
    return true if contest.end_at.past?
    return true if contest.start_at.past? && contest.registered?(user)
    user.present? && (
      user.admin_for_contest?(contest.id) ||
      writer_user_id == user.id ||
      tester_relations.exists?(tester_user_id: user.id, approved: true) ||
      (contest.is_writer_or_tester(user) && (contest.official_mode || contest.start_at.past?))
    )
  end

  def check_admin_or_writer_or_tester(user)
    return false if user.blank?
    user.admin_for_contest?(contest.id) ||
        writer_user_id == user.id ||
        tester_relations.exists?(tester_user_id: user.id, approved: true) ||
        (contest.official_mode && contest.is_writer_or_tester(user))
  end

  def to_param
    slug
  end
end
