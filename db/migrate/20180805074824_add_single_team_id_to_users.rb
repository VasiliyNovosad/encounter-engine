class AddSingleTeamIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :single_team_id, :integer
  end
end
