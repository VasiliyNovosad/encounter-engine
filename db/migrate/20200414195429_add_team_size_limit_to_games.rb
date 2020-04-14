class AddTeamSizeLimitToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :team_size_limit, :integer
  end
end
