class AddIndexByLevelIdToTasks < ActiveRecord::Migration
  def change
    add_index :tasks, :level_id
  end
end
