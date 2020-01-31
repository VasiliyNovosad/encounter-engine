class ChangeTypeColumnsTaskHelpInBonuses < ActiveRecord::Migration[5.2]
  def change
    change_column :bonuses, :task, :text
    change_column :bonuses, :help, :text
  end
end
