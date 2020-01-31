class AddSessionLimitableToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :unique_session_id, :string, limit: 20
  end
end
