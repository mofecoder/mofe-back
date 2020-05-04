class Manage::ProblemSerializer < ContestTaskSerializer
  attributes :id, :writer_user

  def writer_user
    User.find(object.writer_user_id).name
  end
end