class AddColumnClosedLevelsToGamePassings < ActiveRecord::Migration[5.2]
  def change
    add_column :game_passings, :closed_levels, :text
  end
end
