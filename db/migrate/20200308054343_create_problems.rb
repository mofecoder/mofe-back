class CreateProblems < ActiveRecord::Migration[6.0]
  def change
    create_table :problems do |t|
      t.string :slug
      t.string :name
      t.references :contest, foreign_key: true, null: false
      t.string :position
      t.string :difficulty
      t.string :statement
      t.string :constraints
      t.string :input_format
      t.string :output_format
      t.timestamps
    end
  end
end
