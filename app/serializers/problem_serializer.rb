class ProblemSerializer < ActiveModel::Serializer
  attributes :id, :name, :difficulty, :writer_user

  def writer_user
    User.find(object.writer_user_id).name
  end
end
