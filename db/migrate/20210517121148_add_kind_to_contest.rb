class AddKindToContest < ActiveRecord::Migration[6.0]
  def change
    add_column :contests, :kind, :string,
               null: false, after: :description, default: 'normal'
  end
end
