class AddClosedPasswordToContest < ActiveRecord::Migration[6.1]
  def change
    add_column :contests, :closed_password, :string, after: :allow_open_registration
  end
end
