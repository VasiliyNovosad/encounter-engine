class AddTeamToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :questions, :team_id, :integer
  end
end
