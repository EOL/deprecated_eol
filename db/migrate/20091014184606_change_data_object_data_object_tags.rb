class ChangeDataObjectDataObjectTags < ActiveRecord::Migration
  def self.up
    execute "update data_object_data_object_tags dodot join #{DataObject.full_table_name} d on d.id = dodot.data_object_id set data_object_guid = d.guid"
    add_index :data_object_data_object_tags, [:data_object_guid, :data_object_tag_id, :user_id], :name => 'idx_data_object_data_object_tags_1', :unique => true
    
  end

  def self.down
    remove_index :data_object_data_object_tags, :name => 'idx_data_object_data_object_tags_1'
  end
end
