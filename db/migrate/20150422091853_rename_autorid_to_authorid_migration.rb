class RenameAutoridToAuthoridMigration < ActiveRecord::Migration
  def change
    rename_column :games, :autor_id, :author_id
  end
end
