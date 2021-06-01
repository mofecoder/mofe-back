class Manage::ContestSerializer < ContestDetailSerializer
  attributes :official_mode

  def tasks
    ActiveModel::Serializer::CollectionSerializer.new(
        object.problems,
        serializer: Manage::ProblemSerializer
    )
  end
end
