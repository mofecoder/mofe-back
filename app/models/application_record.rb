class ApplicationRecord < ActiveRecord::Base
  include Discard::Model
  self.discard_column = :deleted_at
  self.abstract_class = true

  default_scope -> { kept }
end
