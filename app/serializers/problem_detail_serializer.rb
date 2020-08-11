class ProblemDetailSerializer < UnsetProblemSerializer
  attributes :statement, :constraints, :input_format, :output_format, :samples
end
