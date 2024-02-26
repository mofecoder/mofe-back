class AddIndexToSubmissions < ActiveRecord::Migration[6.1]
  def change
    add_index(:submissions, :user_id)
  end
end
