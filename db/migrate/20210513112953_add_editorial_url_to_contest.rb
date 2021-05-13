class AddEditorialUrlToContest< ActiveRecord::Migration[6.0]
  def change
    add_column :contests, :editorial_url, :string, after: :end_at
  end
end
