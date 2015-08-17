class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :name
      t.string :description
      t.integer :autor_id
      t.datetime :starts_at
      t.boolean :is_draft, :null => false, :default => false
      t.integer :max_team_number
      t.integer :requested_teams_number, :default => 0
      t.datetime :registration_deadline
      t.datetime :author_finished_at
      t.boolean :is_testing, :null => false, :default => false
      t.datetime :test_date
      t.timestamps
    end
  end
end
