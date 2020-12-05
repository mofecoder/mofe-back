class AddAtcoderIdToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :atcoder_id, :string, limit: 16, after: :name
    add_column :users, :atcoder_rating, :integer, after: :atcoder_id
  end
end
