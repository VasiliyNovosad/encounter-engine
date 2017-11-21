class AddOlympBaseToLevel < ActiveRecord::Migration
  def change
    add_column :levels, :olymp_base, :integer, default: 2
  end
end
