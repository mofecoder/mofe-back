class ChangeStringLength < ActiveRecord::Migration[6.0]
  def change
    change_column :problems, :position, :string, limit: 4
    change_column :problems, :difficulty, :string, limit: 16
    change_column :problems, :statement, :string, limit: 4096
    change_column :problems, :constraints, :string, limit: 2048
    change_column :problems, :input_format, :string, limit: 1024
    change_column :problems, :output_format, :string, limit: 1024
    change_column :submits, :status, :string, limit: 16
    change_column :testcase_results, :status, :string, limit: 16
    change_column :testcases, :explanation, :string, limit: 2048
  end
end
