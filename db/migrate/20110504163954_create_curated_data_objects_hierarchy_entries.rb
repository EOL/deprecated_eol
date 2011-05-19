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
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8"
    execute('CREATE INDEX data_object_id ON curated_data_objects_hierarchy_entries(data_object_id)')
    execute('CREATE INDEX data_object_id_hierarchy_entry_id ON curated_data_objects_hierarchy_entries(data_object_id,
            hierarchy_entry_id)')
    en_id = 1
    begin
      en_id = Language.english.id
    rescue
      # Sigh.  We're in an empty DB.
    end
    ChangeableObjectType.create(:ch_object_type => 'curated_data_objects_hierarchy_entry')
    ActionWithObject.reset_column_information # Fixes problems when running ALL migrations.
    awo = ActionWithObject.create
    TranslatedActionWithObject.create(:action_with_object_id => awo.id,
                                      :language_id => en_id,
                                      :action_code => 'add_association',
                                      :phonetic_action_code => 'add_association')
    CuratorActivity.create(:code => 'add_association')
    awo = ActionWithObject.create
    TranslatedActionWithObject.create(:action_with_object_id => awo.id,
                                      :language_id => en_id,
                                      :action_code => 'remove_association',
                                      :phonetic_action_code => 'remove_association')
    CuratorActivity.create(:code => 'remove_association')
  end

  def self.down
    drop_table :curated_data_objects_hierarchy_entries
  end
end
