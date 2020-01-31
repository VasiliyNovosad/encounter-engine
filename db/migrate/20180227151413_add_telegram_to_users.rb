class AddTelegramToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :telegram, :string
  end
end
