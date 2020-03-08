class ContestTaskSerializer < ActiveModel::Serializer
  attributes :slug, :name, :position, :difficulty
end
