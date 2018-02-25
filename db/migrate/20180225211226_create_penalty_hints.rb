class CreatePenaltyHints < ActiveRecord::Migration
  def change
    create_table :penalty_hints do |t|
      t.integer :level_id
      t.string :name
      t.text :text
      t.integer :penalty
      t.integer :team_id

      t.timestamps null: false
    end
  end
end
