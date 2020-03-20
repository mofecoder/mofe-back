class ChangeProblemSlug < ActiveRecord::Migration[6.0]
  def change
    change_column_null :problems, :slug, true
    change_column_null :problems, :position, true
  end
end
