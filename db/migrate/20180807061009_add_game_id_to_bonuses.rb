class AddGameIdToBonuses < ActiveRecord::Migration
  def change
    add_column :bonuses, :game_id, :integer
  end
end
