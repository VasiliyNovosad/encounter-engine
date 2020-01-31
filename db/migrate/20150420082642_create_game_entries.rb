class CreateGameEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :game_entries do |t|
      t.integer :game_id
      t.integer :team_id
      t.string :status
    end
  end
end
