class RenameTraits < ActiveRecord::Migration
  def up
    rename_table :traits, :traits
  end

  def down
    rename_table :traits, :traits
  end
end
