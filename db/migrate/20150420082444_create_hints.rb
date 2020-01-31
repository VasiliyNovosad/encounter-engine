class CreateHints < ActiveRecord::Migration[5.2]
  def change
    create_table :hints do |t|
      t.integer :level_id
      t.string :text
      t.integer :delay
      t.timestamps
    end
  end
end
