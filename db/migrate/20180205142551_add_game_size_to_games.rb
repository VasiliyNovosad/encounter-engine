class AddGameSizeToGames < ActiveRecord::Migration
  def change
    add_column :games, :game_size, :string
  end
end
