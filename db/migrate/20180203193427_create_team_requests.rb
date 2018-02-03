class CreateTeamRequests < ActiveRecord::Migration
  def change
    create_table :team_requests do |t|
      t.integer :team_id
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
