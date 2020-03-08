class CreateTestcaseSets < ActiveRecord::Migration[6.0]
  def change
    create_table :testcase_sets do |t|
      t.references :problem, null: false, foreign_key: true
      t.string :name
      t.integer :points
      t.boolean :is_sample

      t.timestamps
    end
  end
end
