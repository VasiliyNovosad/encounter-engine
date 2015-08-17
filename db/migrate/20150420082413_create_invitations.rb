class CreateInvitations < ActiveRecord::Migration
  def change
    create_table :invitations do |t|
      t.integer :to_team_id
      t.integer :for_user_id
      t.timestamps
    end
  end
end
