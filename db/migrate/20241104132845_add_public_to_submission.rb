class AddPublicToSubmission < ActiveRecord::Migration[6.1]
  def change
    add_column :submissions, :public, :boolean, after: :lang, null: false, default: true
  end
end
