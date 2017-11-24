class AddIdsToLog < ActiveRecord::Migration
  def change
    add_column :logs, :team_id, :integer
    add_column :logs, :level_id, :integer
  end
end
