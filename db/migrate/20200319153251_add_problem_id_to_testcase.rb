class AddProblemIdToTestcase < ActiveRecord::Migration[6.0]
  def change
    add_reference :testcases, :problem, foreign_key: true, after: :id, null: false, default: 1
  end
end
