class AddPartialScoresToProblem < ActiveRecord::Migration[6.1]
  def change
    add_column :problems, :partial_scores, :string, limit: 4096, null: true, after: :constraints
  end
end
