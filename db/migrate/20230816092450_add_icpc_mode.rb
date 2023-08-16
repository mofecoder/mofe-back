class AddIcpcMode < ActiveRecord::Migration[6.1]
  def change
    add_column :contests, :standings_mode, :integer, default: 1, null: false, after: :kind
  end
end
