class CreateQuestions < ActiveRecord::Migration[5.2]
  def change
    create_table :questions do |t|
      t.string :questions
      t.integer :level_id
      t.timestamps
    end
  end
end
