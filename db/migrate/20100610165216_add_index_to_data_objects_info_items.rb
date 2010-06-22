class AddIndexToDataObjectsInfoItems < EOL::DataMigration
  def self.up
    execute("create index info_item_id on data_objects_info_items(info_item_id)")
  end

  def self.down
    remove_index :data_objects_info_items, :name => 'info_item_id'
  end
end
