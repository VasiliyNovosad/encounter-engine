class AddHideFieldsToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :hide_levels_names, :boolean, default: false
    add_column :games, :hide_stat, :boolean, default: false
    add_column :games, :hide_stat_type, :string, default: 'all'
    add_column :games, :hide_stat_level, :integer, default: 0
  end
end
