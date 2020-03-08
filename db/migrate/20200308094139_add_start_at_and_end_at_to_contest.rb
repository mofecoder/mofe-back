class AddStartAtAndEndAtToContest < ActiveRecord::Migration[6.0]
  def change
    add_column :contests, :start_at, :datetime, after: :name
    add_column :contests, :end_at, :datetime, after: :start_at
  end
end
