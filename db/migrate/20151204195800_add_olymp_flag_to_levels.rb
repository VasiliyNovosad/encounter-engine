class AddOlympFlagToLevels < ActiveRecord::Migration[5.2]
  def change
    add_column :levels, :olymp, :boolean, default: false
  end
end
