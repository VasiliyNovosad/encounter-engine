class AddWrongCodePenaltyToLevels < ActiveRecord::Migration[5.2]
  def change
    add_column :levels, :is_wrong_code_penalty, :boolean, default: false
    add_column :levels, :wrong_code_penalty, :integer, default: 0
  end
end
