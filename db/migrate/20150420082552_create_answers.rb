class CreateAnswers < ActiveRecord::Migration[5.2]
  def change
    create_table :answers do |t|
      t.integer :question_id
      t.integer :level_id
      t.string :value
      t.timestamps
    end
  end
end
