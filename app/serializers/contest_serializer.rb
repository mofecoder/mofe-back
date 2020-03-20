class ContestSerializer < ActiveModel::Serializer
  attributes :slug, :name, :start_at, :end_at
end
