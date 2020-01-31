class AddColumnSumBonusesToGamePassing < ActiveRecord::Migration[5.2]
  def change
    add_column :game_passings, :sum_bonuses, :integer, default: 0
  end
end
