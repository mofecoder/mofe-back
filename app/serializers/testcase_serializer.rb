class TestcaseSerializer < ActiveModel::Serializer
  attributes :id, :name, :input, :output, :explanation

  def input
    object.input_data
  end

  def output
    object.output_data
  end
end
