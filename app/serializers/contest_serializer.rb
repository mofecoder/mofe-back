class ContestSerializer < ActiveModel::Serializer
  attributes :slug, :name, :start_at, :end_at, :tasks

  def tasks
    ActiveModel::Serializer::CollectionSerializer.new(
        object.problems,
        serializer: ContestTaskSerializer
    )
  end
end
