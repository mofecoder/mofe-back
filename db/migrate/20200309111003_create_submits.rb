class CreateSubmits < ActiveRecord::Migration[6.0]
  def change
    create_table :submits do |t|
      t.number :user_id
      t.string :path
      t.string :status
      t.integer :point
      t.integer :execution_time
      t.string :execution_memory
      t.string :lang

      t.timestamps
    end
  end
end
