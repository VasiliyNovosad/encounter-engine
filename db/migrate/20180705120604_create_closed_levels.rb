class CreateClosedLevels < ActiveRecord::Migration[5.2]
  def change
    create_table :closed_levels do |t|
      t.integer :game_id
      t.integer :team_id
      t.integer :level_id
      t.integer :user_id
      t.datetime :started_at
      t.datetime :closed_at
      t.boolean :timeouted, default: false

      t.timestamps null: false
    end
  end
end
