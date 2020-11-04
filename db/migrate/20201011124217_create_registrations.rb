class CreateRegistrations < ActiveRecord::Migration[6.0]
  def change
    create_table :registrations do |t|
      t.references :user, null: false
      t.references :contest, null: false

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
