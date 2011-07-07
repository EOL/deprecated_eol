class CreateCuratedDataObjectsHierarchyEntries < ActiveRecord::Migration
  def self.up
    execute "CREATE TABLE IF NOT EXISTS `curated_data_objects_hierarchy_entries` (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      PRIMARY KEY  (`id`),
      `data_object_id` int(10) unsigned NOT NULL,
      `hierarchy_entry_id` int(10) unsigned NOT NULL,
      `user_id` int(10) unsigned NOT NULL,
      `created_at` datetime,
      `updated_at` datetime
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    execute('CREATE INDEX data_object_id ON curated_data_objects_hierarchy_entries(data_object_id)')
    execute('CREATE INDEX data_object_id_hierarchy_entry_id ON curated_data_objects_hierarchy_entries(data_object_id,
            hierarchy_entry_id)')
    en_id = 1
    begin
      en_id = Language.english.id
    rescue
      # Sigh.  We're in an empty DB.
    end
    ChangeableObjectType.create(:ch_object_type => 'hierarchy_entry')
    ChangeableObjectType.create(:ch_object_type => 'curated_data_objects_hierarchy_entry')
    ChangeableObjectType.create(:ch_object_type => 'data_objects_hierarchy_entry')
    Activity.new(:name => 'add_association').save!
    Activity.new(:name => 'remove_association').save!
  end

  def self.down
    drop_table :curated_data_objects_hierarchy_entries
  end
end
