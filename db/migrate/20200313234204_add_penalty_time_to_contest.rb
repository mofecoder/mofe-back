class AddPenaltyTimeToContest < ActiveRecord::Migration[6.0]
  def change
    add_column :contests, :penalty_time, :integer, null: false, default: 0, after: :name
  end
end
