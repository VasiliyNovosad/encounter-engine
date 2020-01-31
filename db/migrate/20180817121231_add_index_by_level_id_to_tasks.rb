class AddIndexByLevelIdToTasks < ActiveRecord::Migration[5.2]
  def change
    add_index :tasks, :level_id
  end
end
