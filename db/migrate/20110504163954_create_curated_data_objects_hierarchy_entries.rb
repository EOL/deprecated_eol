class CreateCuratedDataObjectsHierarchyEntries < ActiveRecord::Migration
  def self.up
    execute "CREATE TABLE IF NOT EXISTS `curated_data_objects_hierarchy_entries` (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      PRIMARY KEY  (`id`),
      `data_object_id` int(10) unsigned NOT NULL,
      `hierarchy_entry_id` int(10) unsigned NOT NULL,
      `user_id` int(10) unsigned NOT NULL,
      `added` tinyint(1) DEFAULT 0,
      `created_at` datetime,
      `updated_at` datetime
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8"
    ChangeableObjectType.create(:ch_object_type => 'curated_data_objects_hierarchy_entry')
    awo = ActionWithObject.create
    TranslatedActionWithObject.create(:action_with_object_id => awo.id,
                                      :language_id => Language.english.id,
                                      :action_code => 'add_association',
                                      :phonetic_action_code => 'add_association')
    CuratorActivity.create(:code => 'add_association')
  end

  def self.down
    drop_table :curated_data_objects_hierarchy_entries
  end
end
