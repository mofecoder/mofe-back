class CreateTeamRegistrations < ActiveRecord::Migration[6.1]
  def change
    create_table :team_registrations do |t|
      t.string :name
      t.string :passphrase
      t.boolean :open_registration

      t.timestamps
      t.datetime :deleted_at
    end

    create_table :team_registration_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :team_registration, null: false, foreign_key: true

      t.timestamps
      t.datetime :deleted_at
    end

    add_index :team_registration_users, [:user_id, :team_registration_id], unique: true, name: 'index_team_registration_users_on_ids'
    add_column :contests, :allow_team_registration, :boolean, default: false, after: :allow_open_registration
  end
end
