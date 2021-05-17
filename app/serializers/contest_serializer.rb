class ContestSerializer < ActiveModel::Serializer
  attributes :slug, :name, :kind, :start_at, :end_at
end
