class RenameColumnFromTypeToGameTypeInGames < ActiveRecord::Migration
  def change
  	rename_column :games, :type, :game_type
  end
end
