class Manage::ContestSerializer < ContestDetailSerializer
  attributes :official_mode, :admins, :closed_password, :allow_open_registration, :allow_team_registration

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
