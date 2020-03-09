class CreateSubmits < ActiveRecord::Migration[6.0]
  def change
    create_table :submits do |t|
      t.integer :user_id, null: false # userテーブルが出来たらreference型にしてforeign key: trueにする
      t.references :problem, null: false, foreign_key: true
      t.string :path, null: false
      t.string :status, null: false
      t.integer :point
      t.integer :execution_time
      t.string :execution_memory
      t.string :lang, null: false

      t.timestamps
    end
  end
end
