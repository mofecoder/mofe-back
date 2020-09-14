class ContestDetailSerializer < ContestSerializer
  attributes :description, :penalty_time, :tasks

  def tasks
    return nil unless @instance_options[:include_tasks]
    ActiveModel::Serializer::CollectionSerializer.new(
        object.problems,
        serializer: ContestTaskSerializer
    )
  end
end
