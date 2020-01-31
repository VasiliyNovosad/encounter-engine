class AddInputLocksToLevels < ActiveRecord::Migration[5.2]
  def change
    add_column :levels, :input_lock, :boolean, default: false
    add_column :levels, :inputs_count, :integer, default: 0
    add_column :levels, :input_lock_duration, :integer, default: 0
    add_column :levels, :input_lock_type, :string, default: 'team'
  end
end
