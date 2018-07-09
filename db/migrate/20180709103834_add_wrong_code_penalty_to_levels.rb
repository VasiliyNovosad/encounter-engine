class AddWrongCodePenaltyToLevels < ActiveRecord::Migration
  def change
    add_column :levels, :is_wrong_code_penalty, :boolean, default: false
    add_column :levels, :wrong_code_penalty, :integer, default: 0
  end
end
