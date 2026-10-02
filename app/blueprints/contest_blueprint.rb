# frozen_string_literal: true

class ContestBlueprint < Blueprinter::Base
  fields :slug, :name, :kind, :start_at, :end_at
end
