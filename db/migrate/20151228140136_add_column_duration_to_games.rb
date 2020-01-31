class AddColumnDurationToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :duration, :integer
  end
end
