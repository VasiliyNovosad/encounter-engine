class AddChangeLevelAutocomplete < ActiveRecord::Migration
  def change
    add_column :questions, :change_level_autocomplete, :boolean, default: false
    add_column :questions, :change_level_autocomplete_by, :integer, default: 0
    add_column :bonuses, :change_level_autocomplete, :boolean, default: false
    add_column :bonuses, :change_level_autocomplete_by, :integer, default: 0
  end
end
