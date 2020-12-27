class AddExcecutionTimeLimitToProblem < ActiveRecord::Migration[6.0]
  def change
    add_column :problems, :execution_time_limit, :integer, null: false, default: 2000, after: :difficulty
  end
end
