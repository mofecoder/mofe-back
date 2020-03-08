class AddValuesToTestcase < ActiveRecord::Migration[6.0]
  def change
    remove_column :testcases, :path
    add_column :testcases, :input, :text,  limit: 4294967295, after: :name
    add_column :testcases, :output, :text, limit: 4294967295, after: :name
  end
end
