class ProblemDetailSerializer < UnsetProblemSerializer
  attributes :execution_time_limit, :statement, :constraints, :input_format, :output_format, :samples, :testers

  def testers
    object.testers.map(&:name)
  end
end
