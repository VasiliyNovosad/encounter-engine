class CreateBonusAnswers < ActiveRecord::Migration[5.2]
  def change
    create_table :bonus_answers do |t|
      t.integer :bonus_id
      t.integer :team_id
      t.string :value
      t.timestamps
    end
  end
end
