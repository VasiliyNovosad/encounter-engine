class AddCompleteLaterToLevels < ActiveRecord::Migration
  def change
  	add_column :levels, :complete_later, :integer
  end
end
