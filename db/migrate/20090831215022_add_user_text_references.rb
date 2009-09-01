class AddUserTextReferences < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  def self.up
    add_column :refs, :user_submitted, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :refs, :user_submitted
  end
end
