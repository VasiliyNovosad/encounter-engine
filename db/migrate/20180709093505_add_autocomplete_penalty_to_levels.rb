class AddAutocompletePenaltyToLevels < ActiveRecord::Migration[5.2]
  def change
    add_column :levels, :is_autocomplete_penalty, :boolean, default: false
    add_column :levels, :autocomplete_penalty, :integer
  end
end
