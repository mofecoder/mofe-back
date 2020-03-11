class SubmitSerializer < ActiveModel::Serializer
  attributes :user_id, :task, :status, :point, :execution_time, :execution_memory, :lang

  def task
    ContestTaskSerializer::new(
        object.problem
    )
  end
end
