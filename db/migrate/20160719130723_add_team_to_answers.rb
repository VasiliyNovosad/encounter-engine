class AddTeamToAnswers < ActiveRecord::Migration[5.2]
  def change
    add_column :answers, :team_id, :integer
  end
end
