class ContestTaskSerializer < ActiveModel::Serializer
  attributes :slug, :name, :position, :difficulty, :points

  def points
    object.testcase_sets.to_a.sum(&:points)
  end
end
