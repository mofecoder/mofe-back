class CreateTestcaseResult < ActiveRecord::Migration[6.0]
  def change
    create_table :testcase_results do |t|
      t.references :submit, null: false
      t.references :testcase, null: false
      t.string :status, null: false
      t.integer :execution_time, null: false
      t.integer :execution_memory, null: false
      t.timestamps
    end
  end
end
