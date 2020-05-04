class ProblemSerializer < UnsetProblemSerializer
  attributes :contest

  def contest
    return nil if object.contest_id.nil?
    {
        name: object.contest.name,
        slug: object.contest.slug
    }
  end
end
