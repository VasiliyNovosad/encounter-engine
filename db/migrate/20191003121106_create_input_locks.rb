class CreateInputLocks < ActiveRecord::Migration
  def change
    create_table :input_locks do |t|
      t.integer :game_id
      t.integer :level_id
      t.integer :team_id
      t.integer :user_id
      t.datetime :lock_ends_at

      t.timestamps null: false
    end
  end
end
