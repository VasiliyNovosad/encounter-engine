class AddColumnAnsweredBonusesToGamePassing < ActiveRecord::Migration[5.2]
  def change
    add_column :game_passings, :answered_bonuses, :text
  end
end
