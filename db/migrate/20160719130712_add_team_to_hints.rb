class AddTeamToHints < ActiveRecord::Migration
  def change
    add_column :hints, :team_id, :integer
  end
end
