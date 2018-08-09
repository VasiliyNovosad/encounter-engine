class AddGameIdIndexes < ActiveRecord::Migration
  def change
    add_index :levels, :game_id
    add_index :game_bonuses, :game_id
  end
end
