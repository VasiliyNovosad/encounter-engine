class AddIndexes < ActiveRecord::Migration
  def change
    add_index :answers, :question_id
    add_index :bonus_answers, :bonus_id
  end
end
