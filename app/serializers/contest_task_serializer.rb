class ContestTaskSerializer < ActiveModel::Serializer
  attributes :slug, :name, :position, :difficulty, :accepted, :points

  def accepted
    @instance_options[:accepted]&.include?(object.id) || false
  end

  def points
    object.testcase_sets.to_a.sum(&:points)
  end
end
