class EditNull < ActiveRecord::Migration[6.0]
  def change
    change_column :contests, :name, :string, null: false
    change_column :problems, :position, :string, null: false
    change_column :problems, :difficulty, :string, null: false
    change_column :problems, :statement, :string, null: false
    change_column :problems, :constraints, :string, null: false
    change_column :problems, :input_format, :string, null: false
    change_column :problems, :output_format, :string, null: false
    change_column :problems, :position, :string, null: false
    change_column :testcase_sets, :name, :string, null: false
    change_column :testcase_sets, :points, :integer, null: false
    change_column :testcase_sets, :is_sample, :boolean, null: false
    change_column :testcases, :input, :text, null: false, limit: 4294967295
    change_column :testcases, :output, :text, null: false, limit: 4294967295, after: :input
  end
end
