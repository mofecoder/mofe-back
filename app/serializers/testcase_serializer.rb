class TestcaseSerializer < ActiveModel::Serializer
  attributes :id, :name, :input, :output, :explanation
end
