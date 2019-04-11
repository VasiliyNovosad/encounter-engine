class CreateResults < ActiveRecord::Migration
  def change
    create_table :results do |t|
      t.integer :game_id
      t.integer :team_id
      t.integer :place

      t.timestamps null: false
    end
  end
end
