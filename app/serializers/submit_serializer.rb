class SubmitSerializer < ActiveModel::Serializer
  attributes :id, :user, :task, :status, :point, :execution_time, :execution_memory, :lang, :timestamp

  def user
    {
        name: object.user.name
    }
  end

  def task
    ContestTaskSerializer::new(
        object.problem
    )
  end

  def timestamp
    object.created_at
  end
end
