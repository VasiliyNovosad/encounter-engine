class AddTopicToGames < ActiveRecord::Migration
  def change
    add_column :games, :topic_id, :integer
  end
end
