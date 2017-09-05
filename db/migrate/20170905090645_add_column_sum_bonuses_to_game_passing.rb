class AddColumnSumBonusesToGamePassing < ActiveRecord::Migration
  def change
    add_column :game_passings, :sum_bonuses, :integer, default: 0
  end
end
