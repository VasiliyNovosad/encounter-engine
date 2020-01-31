class AddGameSizeToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :game_size, :string
  end
end
