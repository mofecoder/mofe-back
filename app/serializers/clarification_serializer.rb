class ClarificationSerializer < ActiveModel::Serializer
  attributes :id, :user, :task, :question, :answer, :publish, :can_answer, :created_at, :updated_at

  def user
    object.user.name
  end

  def task
    return nil unless object.problem
    {
        position: object.problem.position,
        name: object.problem.name,
        slug: object.problem.slug
    }
  end

  def can_answer
    @instance_options[:problems]&.include?(object.problem&.id)
  end
end
