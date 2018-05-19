class ChangeTaskTextColumn < ActiveRecord::Migration
  def change
    change_column :tasks, :text, :text
  end
end
