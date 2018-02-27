class AddFieldsToGames < ActiveRecord::Migration
  def change
    add_column :games, :small_description, :text
    add_column :games, :city, :string
    add_column :games, :place, :string
    add_column :games, :price, :integer
  end
end
