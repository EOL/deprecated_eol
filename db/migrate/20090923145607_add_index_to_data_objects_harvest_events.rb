class AddIndexToDataObjectsHarvestEvents < EOL::DataMigration
  def self.up
    add_index :data_objects_harvest_events, :data_object_id
  end
  def self.down
    remove_index :data_objects_harvest_events, :data_object_id
  end
end
