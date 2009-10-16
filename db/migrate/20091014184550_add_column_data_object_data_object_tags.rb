class AddColumnDataObjectDataObjectTags < ActiveRecord::Migration
  def self.up
    #add_column :data_object_data_object_tags, :data_object_guid, :string, :limit => 32, :null => false, :charset => 'ascii'
    execute "alter table data_object_data_object_tags add column data_object_guid varchar(32) character set ascii not null"
  end

  def self.down
    remove_column :data_object_data_object_tags, :data_object_guid
  end
end
