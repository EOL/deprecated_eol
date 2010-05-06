class ChangeHierarchyStatusToBoolean < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  # I'm not really going to worry about preserving state because I added this migration one day after the last one, and the
  # last one was never really run in production...
  def self.up
    add_column :hierarchies, :request_publish, :boolean, :default => false
    remove_column :hierarchies, :resource_status_id
  end

  def self.down
    add_column :hierarchies, :resource_status_id, :integer, :null => true
    remove_column :hierarchies, :request_publish
  end
end
