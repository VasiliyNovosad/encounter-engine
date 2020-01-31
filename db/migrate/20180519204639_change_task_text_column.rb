class ChangeTaskTextColumn < ActiveRecord::Migration[5.2]
  def change
    change_column :tasks, :text, :text
  end
end
