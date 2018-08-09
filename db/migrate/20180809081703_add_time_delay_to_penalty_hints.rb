class AddTimeDelayToPenaltyHints < ActiveRecord::Migration
  def change
    add_column :penalty_hints, :is_delayed, :boolean, default: false
    add_column :penalty_hints, :delay_for, :integer
  end
end
