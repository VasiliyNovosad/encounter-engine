class AddShowScenarioForToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :show_scenario_for, :text
  end
end
