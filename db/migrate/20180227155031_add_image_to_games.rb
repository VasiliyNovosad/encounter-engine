class AddImageToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :image, :string
  end
end
