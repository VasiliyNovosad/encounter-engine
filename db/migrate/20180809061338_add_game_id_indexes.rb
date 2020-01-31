class AddGameIdIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :levels, :game_id
    add_index :game_bonuses, :game_id
  end
end
