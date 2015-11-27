class ChangeTypeColumnsFromStringToText < ActiveRecord::Migration
  def change
    change_column :games, :description, :text
    change_column :hints, :text, :text
    change_column :levels, :text, :text
  end
end
