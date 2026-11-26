class CreateUploads < ActiveRecord::Migration[8.1]
  def change
    create_table :uploads do |t|
      t.references :user, null: false, foreign_key: true
      # pending: 署名付き URL を発行済み / completed: 検証済み / rejected: 検証で弾いた
      t.string :status, null: false, default: 'pending'
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :uploads, [:user_id, :created_at]
  end
end
