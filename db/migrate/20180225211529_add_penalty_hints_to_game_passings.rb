class AddPenaltyHintsToGamePassings < ActiveRecord::Migration
  def change
    add_column :game_passings, :penalty_hints, :text
  end
end
