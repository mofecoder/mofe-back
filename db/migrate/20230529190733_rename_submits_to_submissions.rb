class RenameSubmitsToSubmissions < ActiveRecord::Migration[6.1]
  def change
    rename_table :submits, :submissions
    rename_column :testcase_results, :submit_id, :submission_id
  end
end
