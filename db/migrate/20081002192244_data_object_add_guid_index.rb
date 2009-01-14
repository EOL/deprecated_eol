class DataObjectAddGuidIndex < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    add_index :data_objects_harvest_events, :guid
    add_index :data_objects, :visibility_id
    add_index :data_objects, :guid
  end

  def self.down
    remove_index :data_objects, :guid
    remove_index :data_objects, :visibility_id
    remove_index :data_objects_harvest_events, :guid
  end
end
