class UnsetProblemSerializer < ActiveModel::Serializer
  attributes :id, :name, :difficulty, :writer_user

  def writer_user
    object.writer_user.name
  end
end
