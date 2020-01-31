class AddPenaltyHintsToGamePassings < ActiveRecord::Migration[5.2]
  def change
    add_column :game_passings, :penalty_hints, :text
  end
end
