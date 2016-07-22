class AddTeamToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :team_id, :integer
  end
end
