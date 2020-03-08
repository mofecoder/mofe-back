class Contest < ApplicationRecord
  include ActiveModel::Serialization
  include ActiveModel::Model

  has_many :problems

  def to_param
    slug
  end
end
