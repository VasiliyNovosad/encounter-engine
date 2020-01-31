class AddCompleteLaterToLevels < ActiveRecord::Migration[5.2]
  def change
  	add_column :levels, :complete_later, :integer
  end
end
