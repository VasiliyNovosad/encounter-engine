class CreateHints < ActiveRecord::Migration
  def change
    create_table :hints do |t|
      t.integer :level_id
      t.string :text
      t.integer :delay
      t.timestamps
    end
  end
end
