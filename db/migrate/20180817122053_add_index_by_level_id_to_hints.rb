class AddIndexByLevelIdToHints < ActiveRecord::Migration[5.2]
  def change
    add_index :hints, :level_id
    add_index :penalty_hints, :level_id
  end
end
