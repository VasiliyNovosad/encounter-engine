class AddColumnAnsweredBonusesToGamePassing < ActiveRecord::Migration
  def change
    add_column :game_passings, :answered_bonuses, :text
  end
end
