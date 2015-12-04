class AddOlympFlagToLevels < ActiveRecord::Migration
  def change
    add_column :levels, :olymp, :boolean, default: false
  end
end
