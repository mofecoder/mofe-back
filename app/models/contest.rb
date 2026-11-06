class Contest < ApplicationRecord
  has_many :problems, -> { order('char_length(`position`)').order(:position) }, dependent: :restrict_with_error
  has_many :clarifications, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :team_registrations, dependent: :destroy
  has_many :contest_admins, dependent: :destroy
  enum :standings_mode, { atcoder: 1, icpc: 2 }, default: :atcoder

  validates :start_at, :end_at, presence: true
  validate :end_at_after_start_at

  def to_param
    slug
  end

  # @param [User] user
  def registered?(user)
    user.present? && (
      user.contest_admin?(self.id) ||
        self.registrations.exists?(user_id: user.id) ||
        self.team_registrations.eager_load(:team_registration_users)
               .exists?(team_registration_users: { user_id: user.id })
    )
  end

  def admin?(user)
    user.present? && (user.admin? || contest_admins.exists?(user: user))
  end

  def writer_or_tester?(user)
    return false if user.nil?
    return true if admin?(user)

    self.problems.exists?(writer_user_id: user.id) ||
      TesterRelation.exists?(problem: self.problems, tester_user_id: user.id, approved: true)
  end

  def ended?
    end_at.past?
  end

  private

  def end_at_after_start_at
    return if start_at.blank? || end_at.blank?

    errors.add(:end_at, :invalid) unless end_at > start_at
  end
end
