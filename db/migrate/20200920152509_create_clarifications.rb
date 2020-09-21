class CreateClarifications < ActiveRecord::Migration[6.0]
  def change
    create_table :clarifications do |t|
      t.references :contest, null: false
      t.references :problem
      t.references :user, null: false
      t.string :question, null: false
      t.string :answer
      t.boolean :publish, null: false, default: false

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
