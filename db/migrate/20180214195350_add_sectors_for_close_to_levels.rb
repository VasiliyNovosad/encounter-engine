class AddSectorsForCloseToLevels < ActiveRecord::Migration
  def change
    add_column :levels, :sectors_for_close, :integer, default: 0
  end
end
