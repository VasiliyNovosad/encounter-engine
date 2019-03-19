class AddDescriptionToLevels < ActiveRecord::Migration
  def change
    add_column :levels, :description, :string, default: 'all'
  end
end
