class ChangeProblemContestId < ActiveRecord::Migration[6.0]
  def change
    change_column_null :problems, :contest_id, true
  end
end
