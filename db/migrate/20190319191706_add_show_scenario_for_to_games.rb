class AddShowScenarioForToGames < ActiveRecord::Migration
  def change
    add_column :games, :show_scenario_for, :text
  end
end
