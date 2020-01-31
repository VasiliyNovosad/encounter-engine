class AddDescriptionToLevels < ActiveRecord::Migration[5.2]
  def change
    add_column :levels, :description, :string, default: 'all'
  end
end
