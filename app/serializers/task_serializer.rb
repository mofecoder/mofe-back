class TaskSerializer < ActiveModel::Serializer
  attributes :slug, :position, :name, :difficulty, :statement, :constraints, :input_format, :output_format, :samples
end
