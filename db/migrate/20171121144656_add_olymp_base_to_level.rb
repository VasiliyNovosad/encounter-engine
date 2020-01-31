class AddOlympBaseToLevel < ActiveRecord::Migration[5.2]
  def change
    add_column :levels, :olymp_base, :integer, default: 2
  end
end
