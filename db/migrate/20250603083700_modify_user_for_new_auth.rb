class ModifyUserForNewAuth < ActiveRecord::Migration[7.2]
  def change
    remove_index :users, column: :confirmation_token
    remove_index :users, column: :reset_password_token
    remove_index :users, column: [:uid, :provider]
    remove_columns :users, :provider, :encrypted_password, :reset_password_token,
                   :reset_password_sent_at, :allow_password_change, :remember_created_at, :sign_in_count,
                   :current_sign_in_at, :last_sign_in_at, :current_sign_in_ip, :last_sign_in_ip,
                   :confirmation_token, :confirmation_sent_at, :unconfirmed_email, :tokens
    add_index :users, :uid, unique: true
  end
end
