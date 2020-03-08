class AddSlug < ActiveRecord::Migration[6.0]
  def change
    change_column :contests, :slug, :string, null: false
    add_index :contests, :slug, unique: true
    change_column :problems, :slug, :string, null: false
    add_index :problems, :slug, unique: true
  end
end
