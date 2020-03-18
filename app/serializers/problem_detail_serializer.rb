class ProblemDetailSerializer < ProblemSerializer
  attributes :statement, :constraints, :input_format, :output_format, :samples
end
