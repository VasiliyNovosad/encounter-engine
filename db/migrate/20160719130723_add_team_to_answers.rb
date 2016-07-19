class AddTeamToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :team_id, :integer
  end
end
