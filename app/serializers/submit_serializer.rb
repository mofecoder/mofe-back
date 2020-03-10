class SubmitSerializer < ActiveModel::Serializer
  attributes :user_id, :contests_slug, :problems_slug, :status, :point, :execution_time, :execution_memory, :lang, :path
end
