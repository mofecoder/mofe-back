class AddWriterUserIdToProblem < ActiveRecord::Migration[6.0]
  def change
    add_reference :problems, :writer_user, foreign_key: { to_table: :users }, after: :contest_id, null: false, default: 1
  end
end
