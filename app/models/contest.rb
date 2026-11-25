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

  # ユーザが登録済みのチーム登録（未所属なら nil）
  # @param [User, nil] user
  def team_registration_of(user)
    return nil if user.nil?

    team_registrations.eager_load(:team_registration_users)
                      .find_by(team_registration_users: { user_id: user.id })
  end

  # 自分を含むチームメンバーの user_id（チーム未所属なら []）
  # @param [User, nil] user
  def teammate_user_ids(user)
    team = team_registration_of(user)
    return [] if team.nil?

    # team_registration_of の eager_load は自分の行だけに絞られるため、メンバーは別途取得する
    TeamRegistrationUser.where(team_registration_id: team.id).pluck(:user_id)
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
