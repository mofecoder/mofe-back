class CreateAllRegistrations < ActiveRecord::Migration[6.1]
  def change
    create_view :all_registrations
  end
end
