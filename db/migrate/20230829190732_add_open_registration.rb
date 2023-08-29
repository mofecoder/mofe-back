class AddOpenRegistration < ActiveRecord::Migration[6.1]
  def change
    add_column :contests, :allow_open_registration, :boolean, default: false, after: :kind
    add_column :registrations, :open_registration, :boolean, default: false, after: :contest_id
  end
end
