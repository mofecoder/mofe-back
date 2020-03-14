class ChangeSubmitExecutionMemory < ActiveRecord::Migration[6.0]
  def change
    change_column :submits, :execution_memory, :integer
  end
end
