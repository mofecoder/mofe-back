class AddOfficialModeToContest < ActiveRecord::Migration[6.0]
  def change
    add_column :contests, :official_mode, :boolean, null: false, default: false,  after: :editorial_url
  end
end
