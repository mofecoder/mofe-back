class CreatePosts < ActiveRecord::Migration[6.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.string :public_status, default: 'private'

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
