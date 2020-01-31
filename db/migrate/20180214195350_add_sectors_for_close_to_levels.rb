class AddSectorsForCloseToLevels < ActiveRecord::Migration[5.2]
  def change
    add_column :levels, :sectors_for_close, :integer, default: 0
  end
end
