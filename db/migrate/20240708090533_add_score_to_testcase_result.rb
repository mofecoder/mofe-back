class AddScoreToTestcaseResult < ActiveRecord::Migration[6.1]
  def change
    add_column :testcase_results, :score, :bigint, after: :status, null: true
    add_column :testcase_sets, :aggregate_type, :integer, after: :points, null: false, default: 0
  end
end
