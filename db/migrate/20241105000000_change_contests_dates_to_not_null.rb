class ChangeContestsDatesToNotNull < ActiveRecord::Migration[6.1]
  def up
    execute 'UPDATE contests SET start_at = created_at WHERE start_at IS NULL'
    execute "UPDATE contests SET end_at = '2100-01-01 00:00:00' WHERE end_at IS NULL"
    change_column_null :contests, :start_at, false
    change_column_null :contests, :end_at, false
  end

  def down
    change_column_null :contests, :start_at, true
    change_column_null :contests, :end_at, true
  end
end
