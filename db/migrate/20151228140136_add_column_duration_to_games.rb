class AddColumnDurationToGames < ActiveRecord::Migration
  def change
    add_column :games, :duration, :integer
  end
end
