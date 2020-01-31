class AddUserToLogs < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :logs, :user
  end
end
