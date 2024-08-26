class ProblemDetailSerializer < UnsetProblemSerializer
  attributes :contest, :slug, :execution_time_limit, :statement,
             :submission_limit_1, :submission_limit_2,
             :constraints, :input_format, :output_format, :checker_path, :samples, :testers

  def contest
    object.contest && ContestSerializer.new(object.contest)
  end

  def testers
    object.testers.map(&:name)
  end
end
