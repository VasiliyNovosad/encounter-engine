class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
    	t.string :email
    	t.string :nickname
    	t.string :crypted_password
    	t.string :salt
    	t.integer :team_id
    	t.string :jabber_id
    	t.string :icq_number
    	t.date :date_of_birth
    	t.string :phone_number
      t.timestamps
    end
  end
end
