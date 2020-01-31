class CreateLevelOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :level_orders do |t|
      t.integer :game_id
      t.integer :team_id
      t.integer :level_id
      t.integer :position
      t.timestamps null: false
    end
  end
end
