class AddDismissedToLevels < ActiveRecord::Migration[5.2]
  def change
    add_column :levels, :dismissed, :boolean, default: false
  end
end
