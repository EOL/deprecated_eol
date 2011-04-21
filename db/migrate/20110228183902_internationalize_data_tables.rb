class InternationalizeDataTables < EOL::DataMigration
  # skipping glossary, licenses
  
  def self.up
    english = Language.find_by_iso_exclusive_scope('en')
    # we need to use SQL to get some numeric types we want (smallint)
    
    # === AgentContactRole
    execute("CREATE TABLE `translated_agent_contact_roles` (
      `id` int NOT NULL auto_increment,
      `agent_contact_role_id` tinyint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(255) NOT NULL,
      `phonetic_label` varchar(255) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`agent_contact_role_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      AgentContactRole.all.each do |r|
        TranslatedAgentContactRole.create(:agent_contact_role_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :agent_contact_roles, :label
    
    
    # === AgentRole
    execute("CREATE TABLE `translated_agent_roles` (
      `id` int NOT NULL auto_increment,
      `agent_role_id` tinyint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`agent_role_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      AgentRole.all.each do |r|
        TranslatedAgentRole.create(:agent_role_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :agent_roles, :label
    
    
    # === AgentStatus
    execute("CREATE TABLE `translated_agent_statuses` (
      `id` int NOT NULL auto_increment,
      `agent_status_id` tinyint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`agent_status_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      AgentStatus.all.each do |r|
        TranslatedAgentStatus.create(:agent_status_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :agent_statuses, :label
    
    
    # === Audience
    execute("CREATE TABLE `translated_audiences` (
      `id` int NOT NULL auto_increment,
      `audience_id` tinyint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`audience_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      Audience.all.each do |r|
        TranslatedAudience.create(:audience_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :audiences, :label
    
    
    # === CollectionType
    execute("CREATE TABLE `translated_collection_types` (
      `id` int NOT NULL auto_increment,
      `collection_type_id` smallint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`collection_type_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      CollectionType.all.each do |r|
        TranslatedCollectionType.create(:collection_type_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :collection_types, :label
    
    
    # === DataType
    execute("CREATE TABLE `translated_data_types` (
      `id` int NOT NULL auto_increment,
      `data_type_id` smallint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`data_type_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      DataType.all.each do |r|
        TranslatedDataType.create(:data_type_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :data_types, :label
    
    
    # === InfoItem
    execute("CREATE TABLE `translated_info_items` (
      `id` int NOT NULL auto_increment,
      `info_item_id` smallint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`info_item_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      InfoItem.all.each do |r|
        TranslatedInfoItem.create(:info_item_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :info_items, :label
    
    
    # === Language
    execute("CREATE TABLE `translated_languages` (
      `id` int NOT NULL auto_increment,
      `original_language_id` smallint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`original_language_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      Language.all.each do |r|
        TranslatedLanguage.create(:original_language_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :languages, :label
    
    
    # === MimeType
    execute("CREATE TABLE `translated_mime_types` (
      `id` int NOT NULL auto_increment,
      `mime_type_id` smallint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`mime_type_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      MimeType.all.each do |r|
        TranslatedMimeType.create(:mime_type_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :mime_types, :label
    
    
    # === Rank
    execute("CREATE TABLE `translated_ranks` (
      `id` int NOT NULL auto_increment,
      `rank_id` smallint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`rank_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      Rank.all.each do |r|
        TranslatedRank.create(:rank_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :ranks, :label
    
    
    # # === RefIdentifierType
    # execute("CREATE TABLE `translated_ref_identifier_types` (
    #   `id` int NOT NULL auto_increment,
    #   `ref_identifier_type_id` smallint unsigned NOT NULL,
    #   `language_id` smallint unsigned NOT NULL,
    #   `label` varchar(300) NOT NULL,
    #   `phonetic_label` varchar(300) default NULL,
    #   PRIMARY KEY (`id`),
    #   UNIQUE (`ref_identifier_type_id`, `language_id`)
    # ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    # if english
    #   RefIdentifierType.all.each do |r|
    #     TranslatedRefIdentifierType.create(:ref_identifier_type_id => r.id, :language_id => english.id, :label => r.label)
    #   end
    # end
    # remove_column :ref_identifier_types, :label
    
    
    # === ResourceAgentRole
    execute("CREATE TABLE `translated_resource_agent_roles` (
      `id` int NOT NULL auto_increment,
      `resource_agent_role_id` tinyint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`resource_agent_role_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      ResourceAgentRole.all.each do |r|
        TranslatedResourceAgentRole.create(:resource_agent_role_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :resource_agent_roles, :label
    
    
    # === ResourceStatus
    execute("CREATE TABLE `translated_resource_statuses` (
      `id` int NOT NULL auto_increment,
      `resource_status_id` int NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`resource_status_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      ResourceStatus.all.each do |r|
        TranslatedResourceStatus.create(:resource_status_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :resource_statuses, :label
    
    
    # === ServiceType
    execute("CREATE TABLE `translated_service_types` (
      `id` int NOT NULL auto_increment,
      `service_type_id` smallint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`service_type_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      ServiceType.all.each do |r|
        TranslatedServiceType.create(:service_type_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :service_types, :label
    
    
    # === Status
    execute("CREATE TABLE `translated_statuses` (
      `id` int NOT NULL auto_increment,
      `status_id` smallint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`status_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      Status.all.each do |r|
        TranslatedStatus.create(:status_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :statuses, :label
    
    
    # === SynonymRelation
    execute("CREATE TABLE `translated_synonym_relations` (
      `id` int NOT NULL auto_increment,
      `synonym_relation_id` smallint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`synonym_relation_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      SynonymRelation.all.each do |r|
        TranslatedSynonymRelation.create(:synonym_relation_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :synonym_relations, :label
    
    
    # === TocItem
    execute("CREATE TABLE `translated_table_of_contents` (
      `id` int NOT NULL auto_increment,
      `table_of_contents_id` smallint unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`table_of_contents_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      TocItem.all.each do |r|
        TranslatedTocItem.create(:table_of_contents_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :table_of_contents, :label
    
    
    # === UntrustReason
    execute("CREATE TABLE `translated_untrust_reasons` (
      `id` int NOT NULL auto_increment,
      `untrust_reason_id` int unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`untrust_reason_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      UntrustReason.all.each do |r|
        TranslatedUntrustReason.create(:untrust_reason_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :untrust_reasons, :label
    
    
    # === Vetted
    execute("CREATE TABLE `translated_vetted` (
      `id` int NOT NULL auto_increment,
      `vetted_id` int unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`vetted_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      Vetted.all.each do |r|
        TranslatedVetted.create(:vetted_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :vetted, :label
    
    
    # === Visibility
    execute("CREATE TABLE `translated_visibilities` (
      `id` int NOT NULL auto_increment,
      `visibility_id` int unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(300) NOT NULL,
      `phonetic_label` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`visibility_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      Visibility.all.each do |r|
        TranslatedVisibility.create(:visibility_id => r.id, :language_id => english.id, :label => r.label)
      end
    end
    remove_column :visibilities, :label
  end

  def self.down
    english = Language.english
    
    # === AgentContactRole
    execute('ALTER TABLE `agent_contact_roles` ADD `label` varchar(100) character set ascii NOT NULL AFTER `id`')
    if english
      TranslatedAgentContactRole.find_all_by_language_id(english.id).each do |r|
        old_r = AgentContactRole.find(r.agent_contact_role_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :agent_contact_roles, :label, :name => 'label'
    drop_table :translated_agent_contact_roles
    
    
    # === AgentRole
    execute('ALTER TABLE `agent_roles` ADD `label` varchar(100) character set ascii NOT NULL AFTER `id`')
    if english
      TranslatedAgentRole.find_all_by_language_id(english.id).each do |r|
        old_r = AgentRole.find(r.agent_role_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :agent_roles, :label, :name => 'label'
    drop_table :translated_agent_roles
    
    
    # === AgentStatus
    execute('ALTER TABLE `agent_statuses` ADD `label` varchar(100) character set ascii NOT NULL AFTER `id`')
    if english
      TranslatedAgentStatus.find_all_by_language_id(english.id).each do |r|
        old_r = AgentStatus.find(r.agent_status_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :agent_statuses, :label, :name => 'label'
    drop_table :translated_agent_statuses
    
    
    # === AgentStatus
    execute('ALTER TABLE `audiences` ADD `label` varchar(100) character set ascii NOT NULL AFTER `id`')
    if english
      TranslatedAudience.find_all_by_language_id(english.id).each do |r|
        old_r = Audience.find(r.audience_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :audiences, :label, :name => 'label'
    drop_table :translated_audiences
    
    
    # === CollectionType
    execute('ALTER TABLE `collection_types` ADD `label` varchar(300) NOT NULL AFTER `rgt`')
    if english
      TranslatedCollectionType.find_all_by_language_id(english.id).each do |r|
        old_r = CollectionType.find(r.collection_type_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :collection_types, :label, :name => 'label'
    drop_table :translated_collection_types
    
    
    # === DataType
    execute('ALTER TABLE `data_types` ADD `label` varchar(255) NOT NULL AFTER `schema_value`')
    if english
      TranslatedDataType.find_all_by_language_id(english.id).each do |r|
        old_r = DataType.find(r.data_type_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :data_types, :label, :name => 'label'
    drop_table :translated_data_types
    
    
    # === InfoItem
    execute('ALTER TABLE `info_items` ADD `label` varchar(255) NOT NULL AFTER `schema_value`')
    if english
      TranslatedInfoItem.find_all_by_language_id(english.id).each do |r|
        old_r = InfoItem.find(r.info_item_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :info_items, :label, :name => 'label'
    drop_table :translated_info_items
    
    
    # === Language
    execute('ALTER TABLE `languages` ADD `label` varchar(100) NOT NULL AFTER `id`')
    Language.reset_column_information  # language is referenced above w/o label, so we need to refresh its fields
    if english
      TranslatedLanguage.find_all_by_language_id(english.id).each do |r|
        old_r = Language.find(r.original_language_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :languages, :label, :name => 'label'
    drop_table :translated_languages
    
    
    # === MimeType
    execute('ALTER TABLE `mime_types` ADD `label` varchar(255) NOT NULL AFTER `id`')
    if english
      TranslatedMimeType.find_all_by_language_id(english.id).each do |r|
        old_r = MimeType.find(r.mime_type_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :mime_types, :label, :name => 'label'
    drop_table :translated_mime_types
    
    
    # === Rank
    execute('ALTER TABLE `ranks` ADD `label` varchar(100) NOT NULL AFTER `id`')
    if english
      TranslatedRank.find_all_by_language_id(english.id).each do |r|
        old_r = Rank.find(r.rank_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :ranks, :label, :name => 'label'
    drop_table :translated_ranks
    
    
    # # === RefIdentifierType
    # execute('ALTER TABLE `ref_identifier_types` ADD `label` varchar(100) NOT NULL AFTER `id`')
    # if english
    #   TranslatedRefIdentifierType.find_all_by_language_id(english.id).each do |r|
    #     old_r = RefIdentifierType.find(r.ref_identifier_type_id)
    #     old_r.label = r.label
    #     old_r.save
    #   end
    # end
    # add_index :ref_identifier_types, :label, :name => 'label'
    # drop_table :translated_ref_identifier_types
    
    # === ResourceAgentRole
    execute('ALTER TABLE `resource_agent_roles` ADD `label` varchar(100) NOT NULL AFTER `id`')
    if english
      TranslatedResourceAgentRole.find_all_by_language_id(english.id).each do |r|
        old_r = ResourceAgentRole.find(r.resource_agent_role_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :resource_agent_roles, :label, :name => 'label'
    drop_table :translated_resource_agent_roles
    
    
    # === ResourceStatus
    execute('ALTER TABLE `resource_statuses` ADD `label` varchar(255) default NULL AFTER `id`')
    if english
      TranslatedResourceStatus.find_all_by_language_id(english.id).each do |r|
        old_r = ResourceStatus.find(r.resource_status_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :resource_statuses, :label, :name => 'label'
    drop_table :translated_resource_statuses
    
    
    # === ServiceType
    execute('ALTER TABLE `service_types` ADD `label` varchar(255) NOT NULL AFTER `id`')
    if english
      TranslatedServiceType.find_all_by_language_id(english.id).each do |r|
        old_r = ServiceType.find(r.service_type_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :service_types, :label, :name => 'label'
    drop_table :translated_service_types
    
    
    # === Status
    execute('ALTER TABLE `statuses` ADD `label` varchar(255) NOT NULL AFTER `id`')
    if english
      TranslatedStatus.find_all_by_language_id(english.id).each do |r|
        old_r = Status.find(r.status_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :statuses, :label, :name => 'label'
    drop_table :translated_statuses
    
    
    # === SynonymRelation
    execute('ALTER TABLE `synonym_relations` ADD `label` varchar(255) NOT NULL AFTER `id`')
    if english
      TranslatedSynonymRelation.find_all_by_language_id(english.id).each do |r|
        old_r = SynonymRelation.find(r.synonym_relation_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :synonym_relations, :label, :name => 'label'
    drop_table :translated_synonym_relations
    
    
    # === TocItem
    execute('ALTER TABLE `table_of_contents` ADD `label` varchar(255) NOT NULL AFTER `parent_id`')
    if english
      TranslatedTocItem.find_all_by_language_id(english.id).each do |r|
        old_r = TocItem.find(r.table_of_contents_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :table_of_contents, :label, :name => 'label'
    drop_table :translated_table_of_contents
    
    
    # === UntrustReason
    execute('ALTER TABLE `untrust_reasons` ADD `label` varchar(255) NOT NULL AFTER `id`')
    if english
      TranslatedUntrustReason.find_all_by_language_id(english.id).each do |r|
        old_r = UntrustReason.find(r.untrust_reason_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :untrust_reasons, :label, :name => 'label'
    drop_table :translated_untrust_reasons
    
    
    # === Vetted
    execute('ALTER TABLE `vetted` ADD `label` varchar(255) default "" AFTER `id`')
    if english
      TranslatedVetted.find_all_by_language_id(english.id).each do |r|
        old_r = Vetted.find(r.vetted_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :vetted, :label, :name => 'label'
    drop_table :translated_vetted
    
    
    # === Visibility
    execute('ALTER TABLE `visibilities` ADD `label` varchar(255) default NULL AFTER `id`')
    if english
      TranslatedVisibility.find_all_by_language_id(english.id).each do |r|
        old_r = Visibility.find(r.visibility_id)
        old_r.label = r.label
        old_r.save
      end
    end
    add_index :visibilities, :label, :name => 'label'
    drop_table :translated_visibilities
  end
end
