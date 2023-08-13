class CreateContestAdmin < ActiveRecord::Migration[6.1]
  def change
    create_table :contest_admins do |t|
      t.references :contest, foreign_key: true, null: false
      t.references :user, foreign_key: true, null: false

      t.timestamps
      t.datetime :deleted_at, true
    end
  end
end
