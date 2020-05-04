class AddDeletedAtToAllTable < ActiveRecord::Migration[6.0]
  def change
    add_column :contests, :deleted_at, :datetime, index: true
    add_column :problems, :deleted_at, :datetime, index: true
    add_column :submits, :deleted_at, :datetime, index: true
    add_column :testcase_results, :deleted_at, :datetime, index: true
    add_column :testcase_sets, :deleted_at, :datetime, index: true
    add_column :testcase_testcase_sets, :deleted_at, :datetime, index: true
    add_column :testcases, :deleted_at, :datetime, index: true
    add_column :users, :deleted_at, :datetime, index: true
  end
end
