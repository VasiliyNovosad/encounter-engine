class CreateLevelsBonuses < ActiveRecord::Migration[5.2]
  def change
    create_table :levels_bonuses, id: false do |t|
      t.belongs_to :bonus, index: true
      t.belongs_to :level, index: true
    end
  end
end
