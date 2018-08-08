class AddIndexToLogs < ActiveRecord::Migration
  def change
    add_index :logs, [:game_id, :level_id, :team_id]
  end
end
