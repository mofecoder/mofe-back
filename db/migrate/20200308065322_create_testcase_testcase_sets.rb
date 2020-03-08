class CreateTestcaseTestcaseSets < ActiveRecord::Migration[6.0]
  def change
    create_table :testcase_testcase_sets do |t|
      t.references :testcase, null: false, foreign_key: true
      t.references :testcase_set, null: false, foreign_key: true

      t.timestamps
    end
  end
end
