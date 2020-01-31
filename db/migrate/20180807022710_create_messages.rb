class CreateMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :messages do |t|
      t.integer :game_id
      t.integer :user_id
      t.string :text
      t.timestamps
    end
  end
end
