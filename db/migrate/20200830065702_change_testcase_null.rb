class ChangeTestcaseNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null :testcases, :input, true
    change_column_null :testcases, :output, true
  end
end
