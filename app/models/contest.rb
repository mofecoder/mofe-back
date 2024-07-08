class Contest < ApplicationRecord
  include ActiveModel::Serialization
  include ActiveModel::Model

  has_many :problems, -> { order('char_length(`position`)').order(:position) }
  has_many :clarifications
  has_many :registrations, dependent: :destroy
  has_many :team_registrations, dependent: :destroy
  has_many :contest_admins, dependent: :destroy
  enum standings_mode: { atcoder: 1, icpc: 2 }

  def to_param
    slug
  end

  # @param [User] user
  def registered?(user)
    user.present? && (
      user.admin_for_contest?(self.id) ||
        self.registrations.exists?(user_id: user.id) ||
        self.team_registrations.eager_load(:team_registration_users)
               .exists?(team_registration_users: { user_id: user.id })
    )
  end

  def is_writer_or_tester(user)
    return false if user.nil?

    return true if user.admin_for_contest?(self.id)

    self.problems.exists?(writer_user_id: user.id) ||
      TesterRelation.exists?(problem: self.problems, tester_user_id: user.id)
  end
end
