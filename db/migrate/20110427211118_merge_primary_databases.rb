class MergePrimaryDatabases < EOL::DataMigration
  def self.up
    # this is a legacy table that needs to be removed - there was a naming conflict with a table in eol_*
    drop_table :collections
    
    eol_database = UsersDataObject.database_name
    eol_data_database = LegacySpeciesSchemaModel.database_name
    tables_in_eol_data = DataObject.connection.select_values("SHOW TABLES FROM #{eol_data_database}")
    tables_in_eol_data.each do |table|
      execute("RENAME TABLE `#{eol_data_database}`.`#{table}` TO `#{eol_database}`.`#{table}`")
    end
  end

  def self.down
    # we really can't undo this - there would be no way of knowing the tables to move short of hardcoding the table names. Here's the 
    # current list from production should we decide this needs to be undone
    eol_data_tables = [
      'agent_contact_roles', 'agent_contacts', 'agent_data_types', 'agent_provided_data_types', 'agent_roles', 'agent_statuses', 'agents',
      'agents_data_objects', 'agents_hierarchy_entries', 'agents_resources', 'agents_synonyms', 'audiences', 'audiences_data_objects',
      'canonical_forms', 'collection_types', 'collection_types_collections', 'collection_types_hierarchies', 'content_partner_agreements',
      'content_partners', 'curated_hierarchy_entry_relationships', 'data_objects', 'data_objects_harvest_events',
      'data_objects_hierarchy_entries', 'data_objects_info_items', 'data_objects_refs', 'data_objects_table_of_contents',
      'data_objects_taxon_concepts', 'data_objects_taxon_concepts_tmp', 'data_objects_untrust_reasons', 'data_types',
      'data_types_taxon_concepts', 'data_types_taxon_concepts_tmp', 'feed_data_objects', 'feed_data_objects_tmp', 'glossary_terms',
      'google_analytics_page_stats', 'google_analytics_partner_summaries', 'google_analytics_partner_taxa', 'google_analytics_summaries',
      'harvest_events', 'harvest_events_hierarchy_entries', 'harvest_process_logs', 'he_relations_tmp', 'hierarchies', 'hierarchies_content',
      'hierarchies_content_tmp', 'hierarchy_entries', 'hierarchy_entries_exploded', 'hierarchy_entries_flattened', 'hierarchy_entries_flattened_tmp',
      'hierarchy_entries_refs', 'hierarchy_entry_relationships', 'hierarchy_entry_stats', 'hierarchy_entry_stats_tmp', 'info_items',
      'info_items_saved', 'item_pages', 'item_pages_tmp', 'languages', 'licenses', 'mime_types', 'name_languages', 'names', 'page_names',
      'page_names_tmp', 'page_stats_dataobjects', 'page_stats_marine', 'page_stats_taxa', 'publication_titles', 'publication_titles_tmp',
      'random_hierarchy_images', 'random_hierarchy_images_tmp', 'ranks', 'ref_identifier_types', 'ref_identifiers', 'refs', 'resource_agent_roles',
      'resource_statuses', 'resources', 'service_types', 'statuses', 'synonym_relations', 'synonyms', 'table_of_contents',
      'table_of_contents_saved', 'taxon_concept_content', 'taxon_concept_content_tmp', 'taxon_concept_metrics', 'taxon_concept_metrics_tmp',
      'taxon_concept_names', 'taxon_concept_stats', 'taxon_concept_stats_tmp', 'taxon_concepts', 'taxon_concepts_exploded',
      'taxon_concepts_exploded_tmp', 'taxon_concepts_flattened', 'taxon_concepts_flattened_tmp', 'title_items', 'title_items_tmp',
      'top_concept_images', 'top_concept_images_tmp', 'top_images', 'top_images_tmp', 'top_species_images', 'top_unpublished_concept_images',
      'top_unpublished_concept_images_tmp', 'top_unpublished_images', 'top_unpublished_images_tmp', 'top_unpublished_species_images',
      'untrust_reasons', 'vetted', 'visibilities', 'wikipedia_queue']
    
    eol_database = UsersDataObject.database_name
    eol_data_database = LegacySpeciesSchemaModel.database_name
    tables_in_eol = User.connection.select_values("SHOW TABLES FROM #{eol_database}")
    eol_data_tables.each do |table|
      if tables_in_eol.include? table
        execute("RENAME TABLE `#{eol_database}`.`#{table}` TO `#{eol_data_database}`.`#{table}`")
      end
    end
    
    execute 'CREATE TABLE `collections` (
        `id` mediumint(8) unsigned NOT NULL auto_increment,
        `agent_id` int(10) unsigned NOT NULL,
        `resource_id` int(11) default NULL,
        `title` varchar(150) NOT NULL,
        `description` varchar(300) NOT NULL,
        `uri` varchar(255) character set ascii NOT NULL,
        `link` varchar(255) character set ascii NOT NULL,
        `logo_cache_url` bigint(20) unsigned default NULL,
        `vetted` tinyint(3) unsigned NOT NULL,
        `ping_host_url` varchar(255) default NULL,
        PRIMARY KEY  (`id`)
      ) ENGINE=InnoDB AUTO_INCREMENT=15505 DEFAULT CHARSET=utf8'
  end
end
