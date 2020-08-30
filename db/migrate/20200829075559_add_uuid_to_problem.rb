class AddUuidToProblem < ActiveRecord::Migration[6.0]
  def change
    add_column :problems, :uuid, :string, after: :position
  end
end
