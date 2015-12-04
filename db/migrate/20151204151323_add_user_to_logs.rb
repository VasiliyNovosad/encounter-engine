class AddUserToLogs < ActiveRecord::Migration
  def change
    add_belongs_to :logs, :user
  end
end
