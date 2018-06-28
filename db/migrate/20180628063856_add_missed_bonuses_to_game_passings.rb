class AddMissedBonusesToGamePassings < ActiveRecord::Migration
  def change
    add_column :game_passings, :missed_bonuses, :text
  end
end
