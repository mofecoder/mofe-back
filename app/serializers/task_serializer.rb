class TaskSerializer < ContestTaskSerializer
  attributes :execution_time_limit, :statement, :constraints, :input_format, :output_format, :samples
end
