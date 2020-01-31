class RenameColumnFromTypeToGameTypeInGames < ActiveRecord::Migration[5.2]
  def change
  	rename_column :games, :type, :game_type
  end
end
