class AddDescriptionToContests < ActiveRecord::Migration[6.0]
  def change
    add_column :contests, :description, :string, limit: 4096, after: :name
  end
end
