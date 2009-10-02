class AddIndexToDataObjectsHarvestEvents < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  def self.up
    add_index :data_objects_harvest_events, :data_object_id
  end
  def self.down
    remove_index :data_objects_harvest_events, :data_object_id
  end
end
