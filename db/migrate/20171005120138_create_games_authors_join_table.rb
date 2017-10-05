class CreateGamesAuthorsJoinTable < ActiveRecord::Migration
  def change
    create_table :games_authors, id: false do |t|
      t.integer :game_id
      t.integer :author_id
    end

    add_index :games_authors, :game_id
    add_index :games_authors, :author_id
  end
end
