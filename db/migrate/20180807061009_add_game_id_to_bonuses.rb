class AddGameIdToBonuses < ActiveRecord::Migration[5.2]
  def change
    add_column :bonuses, :game_id, :integer
  end
end
