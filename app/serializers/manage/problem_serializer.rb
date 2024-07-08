class Manage::ProblemSerializer < ContestTaskSerializer
  attributes :id, :writer_user

  def writer_user
    object.writer_user.name
  end
end
