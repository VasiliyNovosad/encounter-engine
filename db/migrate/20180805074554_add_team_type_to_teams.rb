class AddTeamTypeToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :team_type, :string, default: 'multy'
  end
end
