class SubmitSerializer < ActiveModel::Serializer
  attributes :user_id, :problem_slug, :status, :point, :execution_time, :execution_memory, :lang, :path
end
