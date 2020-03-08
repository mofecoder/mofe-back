class ContestSerializer < ActiveModel::Serializer
  attributes :slug, :name, :tasks

  def tasks
    ActiveModel::Serializer::CollectionSerializer.new(
        object.problems,
        serializer: ContestTaskSerializer
    )
  end
end
