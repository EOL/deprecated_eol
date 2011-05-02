class InternationalizeRemainingDataTables < EOL::DataMigration
  # skipping glossary, licenses

  def self.up
    EOL::DB::toggle_eol_data_connections(:eol_data)
    english = Language.english
    # we need to use SQL to get some numeric types we want (smallint)

    # === AgentDataType
    execute("CREATE TABLE `translated_agent_data_types` (
      `id` int NOT NULL auto_increment,
      `agent_data_type_id` tinyint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(255) NOT NULL,
      `phonetic_label` varchar(255) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`agent_data_type_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      AgentDataType.all.each do |r|
        TranslatedAgentDataType.create(:agent_data_type_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :agent_data_types, :label


    # === License
    execute("CREATE TABLE `translated_licenses` (
      `id` int NOT NULL auto_increment,
      `license_id` smallint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `description` varchar(400) NOT NULL,
      `phonetic_description` varchar(400) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`license_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      License.all.each do |r|
        TranslatedLicense.create(:license_id => r.id, :language_id => english.id, :description => r.description)
      end
    end
    remove_column :licenses, :description
    EOL::DB::toggle_eol_data_connections(:eol)
  end

  def self.down
    EOL::DB::toggle_eol_data_connections(:eol_data)
    english = Language.english

    # === AgentContactRole
    execute('ALTER TABLE `agent_data_types` ADD `label` varchar(100) character set ascii NOT NULL AFTER `id`')
    if english
      TranslatedAgentDataType.find_all_by_language_id(english.id).each do |r|
        old_r = AgentDataType.find(r.agent_data_type_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :agent_data_types, :label, :name => 'label'
    drop_table :translated_agent_data_types


    # === License
    execute('ALTER TABLE `licenses` ADD `description` varchar(100) NOT NULL AFTER `title`')
    if english
      TranslatedLicense.find_all_by_language_id(english.id).each do |r|
        old_r = License.find(r.license_id)
        old_r.description = r.description
        old_r.save
      end
    end
    drop_table :translated_licenses
    EOL::DB::toggle_eol_data_connections(:eol)
  end
end
