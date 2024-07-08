class TestcaseSetSerializer < ActiveModel::Serializer
  attributes :name, :points, :is_sample, :aggregate_type
end
