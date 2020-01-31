class AddSingleTeamIdToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :single_team_id, :integer
  end
end
