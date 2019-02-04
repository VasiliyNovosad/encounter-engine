class CreateGamePassingsBonuses < ActiveRecord::Migration
  def change
    create_table :game_passings_bonuses do |t|
      t.belongs_to :game_passing, index: true
      t.belongs_to :bonus, index: true
    end
  end
end
