class CreateBonuses < ActiveRecord::Migration[5.2]
  def change
    create_table :bonuses do |t|
      t.integer :level_id
      t.string :name
      t.string :task
      t.string :help
      t.integer :team_id
      t.integer :award_time
      t.integer :position
      t.timestamps
    end
  end
end
