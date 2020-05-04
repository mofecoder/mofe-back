class Manage::ContestSerializer < ContestDetailSerializer
  def tasks
    ActiveModel::Serializer::CollectionSerializer.new(
        object.problems,
        serializer: Manage::ProblemSerializer
    )
  end
end
