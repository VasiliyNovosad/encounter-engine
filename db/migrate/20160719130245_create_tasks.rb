class CreateTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.integer :level_id
      t.string :text
      t.integer :team_id
      t.timestamps
    end
  end
end
