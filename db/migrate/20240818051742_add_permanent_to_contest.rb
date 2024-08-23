class AddPermanentToContest < ActiveRecord::Migration[6.1]
  def change
    add_column :contests, :permanent, :boolean, default: false, null: false, after: :end_at
  end
end
