class Contest < ApplicationRecord
  include ActiveModel::Serialization
  include ActiveModel::Model

  has_many :problems, -> { order(:position) }

  def to_param
    slug
  end
end
