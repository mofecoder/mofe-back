class AddSubmissionLimitsToProblem < ActiveRecord::Migration[6.1]
  def change
    add_column :problems, :submission_limit_1, :integer, after: :execution_time_limit, null: false, default: 5
    add_column :problems, :submission_limit_2, :integer, after: :submission_limit_1, null: false, default: 60
  end
end
