class AddTeamToHints < ActiveRecord::Migration[5.2]
  def change
    add_column :hints, :team_id, :integer
  end
end
