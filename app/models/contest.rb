class Contest < ApplicationRecord
  include ActiveModel::Serialization
  include ActiveModel::Model

  has_many :problems, -> { order(:position) }

  def to_param
    slug
  end

  def is_writer_or_tester(user)
    return false if user.nil?

    return true if user.admin?

    writers = self.problems.pluck(:writer_user_id)
    return true if writers.include?(user.id)

    testers = TesterRelation.where(problem: self.problems).pluck(:tester_user_id)
    testers.include?(user.id)
  end
end
