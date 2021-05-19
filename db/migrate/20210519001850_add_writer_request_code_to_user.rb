class AddWriterRequestCodeToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :writer_request_code, :string, after: :atcoder_rating
  end
end
