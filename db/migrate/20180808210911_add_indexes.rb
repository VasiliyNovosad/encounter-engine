class AddIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :answers, :question_id
    add_index :bonus_answers, :bonus_id
  end
end
