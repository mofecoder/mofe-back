class ProblemDetailSerializer < UnsetProblemSerializer
  attributes :statement, :constraints, :input_format, :output_format, :samples, :testers

  def testers
    object.testers.map(&:name)
  end
end
