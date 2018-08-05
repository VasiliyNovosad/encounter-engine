class AddTeamTypeToGames < ActiveRecord::Migration
  def change
    add_column :games, :team_type, :string, default: 'multy'
  end
end
