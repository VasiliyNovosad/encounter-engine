class AddTestedTeamColumnToGames < ActiveRecord::Migration
  def change
    add_column :games, :tested_team_id, :integer
  end
end
