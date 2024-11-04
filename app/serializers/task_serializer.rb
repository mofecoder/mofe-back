class TaskSerializer < ContestTaskSerializer
  attributes :execution_time_limit, :statement, :constraints, :partial_scores, :input_format, :output_format, :samples
end
