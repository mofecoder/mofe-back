class AddCheckerPathToProblem < ActiveRecord::Migration[6.0]
  def change
    add_column :problems, :checker_path, :string, null: true, after: :output_format
  end
end
