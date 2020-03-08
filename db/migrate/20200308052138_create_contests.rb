class CreateContests < ActiveRecord::Migration[6.0]
  def change
    create_table :contests do |t|
      t.string :slug
      t.string :name

      t.timestamps
    end
  end
end
