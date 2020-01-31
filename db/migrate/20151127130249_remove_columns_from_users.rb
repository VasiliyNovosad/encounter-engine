class RemoveColumnsFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :jabber_id, :string
    remove_column :users, :icq_number, :string
    remove_column :users, :date_of_birth, :string
  end
end
