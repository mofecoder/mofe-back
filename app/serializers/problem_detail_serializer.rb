class ProblemDetailSerializer < UnsetProblemSerializer
  attributes :contest, :slug, :execution_time_limit, :statement, :constraints, :input_format, :output_format, :checker_path, :samples, :testers

  def contest
    object.contest && ContestSerializer.new(object.contest)
  end

  def testers
    object.testers.map(&:name)
  end
end
