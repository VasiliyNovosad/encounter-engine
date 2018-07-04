class AddAnswerTypeToLogs < ActiveRecord::Migration
  def change
    add_column :logs, :answer_type, :integer, default: 0
  end
end
