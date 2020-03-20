class ContestDetailSerializer < ContestSerializer
  attributes :description, :penalty_time, :tasks

  def tasks
    ActiveModel::Serializer::CollectionSerializer.new(
        object.problems,
        serializer: ContestTaskSerializer
    )
  end
end
