class AddApprovedToTesterRelation < ActiveRecord::Migration[6.0]
  def change
    add_column :tester_relations, :approved, :boolean, null: false
    add_timestamps :tester_relations
    add_column :tester_relations, :deleted_at, :datetime, index: true
  end
end
