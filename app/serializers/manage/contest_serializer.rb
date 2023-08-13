class Manage::ContestSerializer < ContestDetailSerializer
  attributes :official_mode, :admins

  def tasks
    ActiveModel::Serializer::CollectionSerializer.new(
        object.problems,
        serializer: Manage::ProblemSerializer
    )
  end

  def admins
    object.contest_admins.includes(:user).map(&:user).map(&:name)
  end
end
