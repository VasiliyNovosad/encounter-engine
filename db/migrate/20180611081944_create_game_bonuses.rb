class CreateGameBonuses < ActiveRecord::Migration[5.2]
  def change
    create_table :game_bonuses do |t|
      t.integer :game_id
      t.integer :team_id
      t.integer :level_id
      t.decimal :award, precision: 16, scale: 3
      t.text :description
      t.integer :user_id
      t.string :reason

      t.timestamps null: false
    end
  end
end
