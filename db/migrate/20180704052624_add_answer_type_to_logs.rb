class AddAnswerTypeToLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :logs, :answer_type, :integer, default: 0
  end
end
