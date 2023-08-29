class DeleteTrueFromContestAdmins < ActiveRecord::Migration[6.1]
  def change
    remove_column :contest_admins, :true
  end
end
