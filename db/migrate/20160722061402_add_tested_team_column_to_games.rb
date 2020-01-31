class AddTestedTeamColumnToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :tested_team_id, :integer
  end
end
