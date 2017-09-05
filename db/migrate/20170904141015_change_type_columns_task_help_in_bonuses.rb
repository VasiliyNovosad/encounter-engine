class ChangeTypeColumnsTaskHelpInBonuses < ActiveRecord::Migration
  def change
    change_column :bonuses, :task, :text
    change_column :bonuses, :help, :text
  end
end
