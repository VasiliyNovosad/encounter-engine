class CreateLevels < ActiveRecord::Migration
  def change
    create_table :levels do |t|
      t.text :text
      t.integer :game_id
      t.integer :position
      t.string :name
      t.timestamps
    end
  end
end
