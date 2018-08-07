class CreateMessagesLevels < ActiveRecord::Migration
  def change
    create_table :messages_levels, id: false do |t|
      t.belongs_to :message, index: true
      t.belongs_to :level, index: true
    end
  end
end
