class AddColumnTypeToGames < ActiveRecord::Migration
  def change
    add_column :games, :type, :string, default: 'linear'
  end
end
