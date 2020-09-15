class CreateTesterRelation < ActiveRecord::Migration[6.0]
  def change
    create_table :tester_relations do |t|
      t.references :problem, null: false, foreign_key: true
      t.references :tester_user, null: false, foreign_key: { to_table: 'users' }
    end
  end
end
