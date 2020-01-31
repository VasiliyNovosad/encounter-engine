class AddTimeLimitsToBonuses < ActiveRecord::Migration[5.2]
  def change
    add_column :bonuses, :is_absolute_limited, :boolean, default: false
    add_column :bonuses, :valid_from, :datetime
    add_column :bonuses, :valid_to, :datetime
    add_column :bonuses, :is_delayed, :boolean, default: false
    add_column :bonuses, :delay_for, :integer
    add_column :bonuses, :is_relative_limited, :boolean, default: false
    add_column :bonuses, :valid_for, :integer
  end
end
