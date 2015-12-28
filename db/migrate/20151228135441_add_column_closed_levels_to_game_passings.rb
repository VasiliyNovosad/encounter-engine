class AddColumnClosedLevelsToGamePassings < ActiveRecord::Migration
  def change
    add_column :game_passings, :closed_levels, :text
  end
end
