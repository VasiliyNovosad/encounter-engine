class AddSlugToGames < ActiveRecord::Migration
  def change
    add_column :games, :slug, :string
    add_index :games, :slug
  end
end
