class AddPositionToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :position, :integer
    rename_column :questions, :questions, :name
  end
end
