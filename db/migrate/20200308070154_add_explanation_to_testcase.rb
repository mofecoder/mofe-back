class AddExplanationToTestcase < ActiveRecord::Migration[6.0]
  def change
    add_column :testcases, :explanation, :string, after: :path
  end
end
