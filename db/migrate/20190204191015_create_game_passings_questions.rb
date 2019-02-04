class CreateGamePassingsQuestions < ActiveRecord::Migration
  def change
    create_table :game_passings_questions do |t|
      t.belongs_to :game_passing, index: true
      t.belongs_to :question, index: true
    end
  end
end
