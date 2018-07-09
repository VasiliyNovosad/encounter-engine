class AddDismissedToLevels < ActiveRecord::Migration
  def change
    add_column :levels, :dismissed, :boolean, default: false
  end
end
