class CreateTeamRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :team_requests do |t|
      t.integer :team_id
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
