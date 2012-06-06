class AddDataObjectGuidToCuratedDataObjectsHierarchyEntries < ActiveRecord::Migration
  def self.up
    add_column :curated_data_objects_hierarchy_entries, :data_object_guid, :string, :limit => 32, :after => :data_object_id
    execute "UPDATE curated_data_objects_hierarchy_entries, data_objects SET curated_data_objects_hierarchy_entries.data_object_guid=data_objects.guid WHERE curated_data_objects_hierarchy_entries.data_object_id=data_objects.id"
  end

  def self.down
    remove_column :curated_data_objects_hierarchy_entries, :data_object_guid
  end
end