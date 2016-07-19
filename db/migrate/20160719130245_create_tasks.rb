class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.integer :level_id
      t.string :text
      t.integer :team_id
      t.timestamps
    end
  end
end
