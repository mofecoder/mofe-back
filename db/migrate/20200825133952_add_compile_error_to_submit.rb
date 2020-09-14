class AddCompileErrorToSubmit < ActiveRecord::Migration[6.0]
  def change
    add_column :submits, :compile_error, :text, after: :execution_memory
  end
end
