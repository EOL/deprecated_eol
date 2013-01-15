class CreateLanguageGroups < ActiveRecord::Migration
  def self.up
    execute "CREATE TABLE `language_groups` (
      `id` smallint unsigned NOT NULL AUTO_INCREMENT,
      `representative_language_id` smallint unsigned NOT NULL,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    execute "ALTER TABLE languages ADD language_group_id smallint unsigned DEFAULT NULL"

    # Create the language group for CN and ZH-Hans
    cn = Language.find_by_translated(:label, 'cn')
    zhhans = Language.from_iso('zh-hans')
    if cn && zhhans
      cn_group = LanguageGroup.create(:representative_language_id => zhhans.id)
      cn.update_attributes(:language_group_id => cn_group.id)
      zhhans.update_attributes(:language_group_id => cn_group.id)
    end
  end

  def self.down
    drop_table :language_groups
    remove_column :languages, :language_group_id
  end
end
