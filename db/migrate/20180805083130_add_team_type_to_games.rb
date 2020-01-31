class AddTeamTypeToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :team_type, :string, default: 'multy'
  end
end
