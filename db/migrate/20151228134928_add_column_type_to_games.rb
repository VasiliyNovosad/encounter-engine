class AddColumnTypeToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :type, :string, default: 'linear'
  end
end
