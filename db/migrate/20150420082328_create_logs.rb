class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.integer :game_id
      t.string :team
      t.string :level
      t.string :answer
      t.datetime :time
    end
  end
end
