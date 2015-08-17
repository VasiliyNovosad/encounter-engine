class CreateGamePassings < ActiveRecord::Migration
  def change
    create_table :game_passings do |t|
      t.integer :game_id
      t.integer :team_id
      t.integer :current_level_id
      t.datetime :finished_at
      t.datetime :current_level_entered_at
      t.text :answered_questions, :limit => 255
      t.string :status
      t.timestamps
    end
  end
end
