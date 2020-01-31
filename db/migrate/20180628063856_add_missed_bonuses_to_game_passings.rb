class AddMissedBonusesToGamePassings < ActiveRecord::Migration[5.2]
  def change
    add_column :game_passings, :missed_bonuses, :text
  end
end
