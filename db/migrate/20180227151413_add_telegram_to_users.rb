class AddTelegramToUsers < ActiveRecord::Migration
  def change
    add_column :users, :telegram, :string
  end
end
