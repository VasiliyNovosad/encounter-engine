class AddIdsToLog < ActiveRecord::Migration[5.2]
  def change
    add_column :logs, :team_id, :integer
    add_column :logs, :level_id, :integer
  end
end
