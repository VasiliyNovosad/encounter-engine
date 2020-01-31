class AddIndexToLogs < ActiveRecord::Migration[5.2]
  def change
    add_index :logs, [:game_id, :level_id, :team_id]
  end
end
