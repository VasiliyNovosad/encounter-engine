class AddTeamTypeToTeams < ActiveRecord::Migration[5.2]
  def change
    add_column :teams, :team_type, :string, default: 'multy'
  end
end
