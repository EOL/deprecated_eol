class RenameTraits < ActiveRecord::Migration
  def up
    rename_table :traits, :traits
    Comment.where(parent_type: "DataPointUri").update_all(parent_type: "Trait")
  end

  def down
    rename_table :traits, :traits
  end
end
