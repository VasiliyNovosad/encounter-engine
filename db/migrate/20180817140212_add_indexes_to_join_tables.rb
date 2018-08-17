class AddIndexesToJoinTables < ActiveRecord::Migration
  def change
    add_index :levels_bonuses, [:level_id, :bonus_id]
    add_index :messages_levels, [:level_id, :message_id]
  end
end
