class RenameAutoridToAuthoridMigration < ActiveRecord::Migration[5.2]
  def change
    rename_column :games, :autor_id, :author_id
  end
end
