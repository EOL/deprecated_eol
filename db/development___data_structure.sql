CREATE TABLE `agent_contact_roles` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `label` varchar(100) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `agent_contacts` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL,
  `agent_contact_role_id` tinyint(3) unsigned NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `title` varchar(20) NOT NULL,
  `given_name` varchar(255) NOT NULL,
  `family_name` varchar(255) NOT NULL,
  `homepage` varchar(255) character set ascii NOT NULL,
  `email` varchar(75) NOT NULL,
  `telephone` varchar(30) character set ascii NOT NULL,
  `address` text NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

CREATE TABLE `agent_data_types` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `label` varchar(100) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;

CREATE TABLE `agent_provided_data_types` (
  `agent_data_type_id` int(10) unsigned NOT NULL,
  `agent_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`agent_data_type_id`,`agent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `agent_roles` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `label` varchar(100) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;

CREATE TABLE `agent_statuses` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `label` varchar(100) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `agents` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `full_name` varchar(255) NOT NULL,
  `acronym` varchar(20) NOT NULL,
  `display_name` varchar(255) NOT NULL,
  `homepage` varchar(255) character set ascii NOT NULL,
  `email` varchar(75) NOT NULL,
  `username` varchar(100) NOT NULL,
  `hashed_password` varchar(100) NOT NULL,
  `remember_token` varchar(255) default NULL,
  `remember_token_expires_at` timestamp NULL default NULL,
  `logo_url` varchar(255) character set ascii default NULL,
  `logo_cache_url` bigint(20) unsigned default NULL,
  `logo_file_name` varchar(255) default NULL,
  `logo_content_type` varchar(255) default NULL,
  `logo_file_size` int(10) unsigned default '0',
  `agent_status_id` tinyint(4) NOT NULL,
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`id`),
  KEY `full_name` (`full_name`)
) ENGINE=InnoDB AUTO_INCREMENT=859358896 DEFAULT CHARSET=utf8;

CREATE TABLE `agents_data_objects` (
  `data_object_id` int(10) unsigned NOT NULL,
  `agent_id` int(10) unsigned NOT NULL,
  `agent_role_id` tinyint(3) unsigned NOT NULL,
  `view_order` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`data_object_id`,`agent_id`,`agent_role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `agents_hierarchy_entries` (
  `hierarchy_entry_id` int(10) unsigned NOT NULL,
  `agent_id` int(10) unsigned NOT NULL,
  `agent_role_id` tinyint(3) unsigned NOT NULL,
  `view_order` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`hierarchy_entry_id`,`agent_id`,`agent_role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `agents_resources` (
  `agent_id` int(10) unsigned NOT NULL,
  `resource_id` int(10) unsigned NOT NULL,
  `resource_agent_role_id` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`agent_id`,`resource_id`,`resource_agent_role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `agents_synonyms` (
  `synonym_id` int(10) unsigned NOT NULL,
  `agent_id` int(10) unsigned NOT NULL,
  `agent_role_id` tinyint(3) unsigned NOT NULL,
  `view_order` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`synonym_id`,`agent_id`,`agent_role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `audiences` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `label` varchar(100) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `audiences_data_objects` (
  `data_object_id` int(10) unsigned NOT NULL,
  `audience_id` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`data_object_id`,`audience_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `canonical_forms` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `string` varchar(300) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `string` (`string`(255))
) ENGINE=InnoDB AUTO_INCREMENT=413836643 DEFAULT CHARSET=utf8;

CREATE TABLE `clean_names` (
  `name_id` int(10) unsigned NOT NULL,
  `clean_name` varchar(300) character set utf8 collate utf8_bin NOT NULL,
  PRIMARY KEY  (`name_id`),
  KEY `clean_name` (`clean_name`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `collections` (
  `id` mediumint(8) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL,
  `title` varchar(150) NOT NULL,
  `description` varchar(300) NOT NULL,
  `uri` varchar(255) character set ascii NOT NULL,
  `link` varchar(255) character set ascii NOT NULL,
  `logo_url` varchar(255) character set ascii NOT NULL,
  `vetted` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;

CREATE TABLE `common_names` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `common_name` varchar(255) NOT NULL,
  `language_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `common_name` (`common_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `common_names_taxa` (
  `taxon_id` int(10) unsigned NOT NULL,
  `common_name_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`taxon_id`,`common_name_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `content_partner_agreements` (
  `id` int(11) NOT NULL auto_increment,
  `agent_id` int(11) NOT NULL,
  `template` text NOT NULL,
  `is_current` tinyint(1) NOT NULL default '1',
  `number_of_views` int(11) NOT NULL default '0',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `last_viewed` datetime default NULL,
  `mou_url` varchar(255) default NULL,
  `ip_address` varchar(255) default NULL,
  `signed_on_date` datetime default NULL,
  `signed_by` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `content_partners` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(11) NOT NULL,
  `description_of_data` text,
  `partner_seen_step` timestamp NULL default NULL,
  `partner_complete_step` timestamp NULL default NULL,
  `contacts_seen_step` timestamp NULL default NULL,
  `contacts_complete_step` timestamp NULL default NULL,
  `licensing_seen_step` timestamp NULL default NULL,
  `licensing_complete_step` timestamp NULL default NULL,
  `attribution_seen_step` timestamp NULL default NULL,
  `attribution_complete_step` timestamp NULL default NULL,
  `roles_seen_step` timestamp NULL default NULL,
  `roles_complete_step` timestamp NULL default NULL,
  `transfer_overview_seen_step` timestamp NULL default NULL,
  `transfer_overview_complete_step` timestamp NULL default NULL,
  `transfer_upload_seen_step` timestamp NULL default NULL,
  `transfer_upload_complete_step` timestamp NULL default NULL,
  `specialist_overview_seen_step` timestamp NULL default NULL,
  `specialist_overview_complete_step` timestamp NULL default NULL,
  `specialist_formatting_seen_step` timestamp NULL default NULL,
  `specialist_formatting_complete_step` timestamp NULL default NULL,
  `vetted` tinyint(4) NOT NULL default '0',
  `description` text NOT NULL,
  `last_completed_step` varchar(40) default NULL,
  `notes` text NOT NULL,
  `ipr_accept` tinyint(4) NOT NULL default '0',
  `attribution_accept` tinyint(4) NOT NULL default '0',
  `roles_accept` tinyint(4) NOT NULL default '0',
  `transfer_schema_accept` tinyint(4) NOT NULL default '0',
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL default '0000-00-00 00:00:00',
  `eol_notified_of_acceptance` datetime default NULL,
  `auto_publish` tinyint(1) NOT NULL default '0',
  `show_on_partner_page` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `data_objects` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `guid` varchar(32) character set ascii NOT NULL,
  `data_type_id` smallint(5) unsigned NOT NULL,
  `mime_type_id` smallint(5) unsigned NOT NULL,
  `object_title` varchar(255) NOT NULL,
  `language_id` smallint(5) unsigned NOT NULL,
  `license_id` tinyint(3) unsigned NOT NULL,
  `rights_statement` varchar(300) NOT NULL,
  `rights_holder` varchar(255) NOT NULL,
  `bibliographic_citation` varchar(300) NOT NULL,
  `source_url` varchar(255) character set ascii NOT NULL,
  `description` text NOT NULL,
  `object_url` varchar(255) character set ascii NOT NULL,
  `object_cache_url` bigint(20) unsigned default NULL,
  `thumbnail_url` varchar(255) character set ascii NOT NULL,
  `thumbnail_cache_url` bigint(20) unsigned default NULL,
  `location` varchar(255) NOT NULL,
  `latitude` double NOT NULL,
  `longitude` double NOT NULL,
  `altitude` double NOT NULL,
  `object_created_at` timestamp NOT NULL default '0000-00-00 00:00:00',
  `object_modified_at` timestamp NOT NULL default '0000-00-00 00:00:00',
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL default '0000-00-00 00:00:00',
  `data_rating` float NOT NULL,
  `vetted_id` tinyint(3) unsigned NOT NULL,
  `visibility_id` int(11) default NULL,
  `published` tinyint(1) NOT NULL default '0',
  `curated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `data_type_id` (`data_type_id`),
  KEY `index_data_objects_on_visibility_id` (`visibility_id`),
  KEY `index_data_objects_on_guid` (`guid`),
  KEY `index_data_objects_on_published` (`published`)
) ENGINE=InnoDB AUTO_INCREMENT=565874095 DEFAULT CHARSET=utf8;

CREATE TABLE `data_objects_harvest_events` (
  `harvest_event_id` int(10) unsigned NOT NULL,
  `data_object_id` int(10) unsigned NOT NULL,
  `guid` varchar(32) character set ascii NOT NULL,
  `status_id` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`harvest_event_id`,`data_object_id`),
  KEY `index_data_objects_harvest_events_on_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `data_objects_info_items` (
  `data_object_id` int(10) unsigned NOT NULL,
  `info_item_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`data_object_id`,`info_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `data_objects_refs` (
  `data_object_id` int(10) unsigned NOT NULL,
  `ref_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`data_object_id`,`ref_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `data_objects_table_of_contents` (
  `data_object_id` int(10) unsigned NOT NULL,
  `toc_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`data_object_id`,`toc_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `data_objects_taxa` (
  `taxon_id` int(10) unsigned NOT NULL,
  `data_object_id` int(10) unsigned NOT NULL,
  `identifier` varchar(255) character set ascii NOT NULL,
  PRIMARY KEY  (`taxon_id`,`data_object_id`),
  KEY `data_object_id` (`data_object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `data_types` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `schema_value` varchar(255) character set ascii NOT NULL,
  `label` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;

CREATE TABLE `harvest_events` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `resource_id` varchar(100) character set ascii NOT NULL,
  `began_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `completed_at` timestamp NULL default NULL,
  `published_at` timestamp NULL default NULL,
  PRIMARY KEY  (`id`),
  KEY `resource_id` (`resource_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

CREATE TABLE `harvest_events_taxa` (
  `harvest_event_id` int(10) unsigned NOT NULL,
  `taxon_id` int(10) unsigned NOT NULL,
  `guid` varchar(32) character set ascii NOT NULL,
  `status_id` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`harvest_event_id`,`taxon_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `hierarchies` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL,
  `label` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `indexed_on` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `hierarchy_group_id` int(10) unsigned NOT NULL,
  `hierarchy_group_version` tinyint(3) unsigned NOT NULL,
  `url` varchar(255) character set ascii NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=108 DEFAULT CHARSET=utf8;

CREATE TABLE `hierarchies_content` (
  `hierarchy_entry_id` int(10) unsigned NOT NULL,
  `text` tinyint(3) unsigned NOT NULL,
  `image` tinyint(3) unsigned NOT NULL,
  `child_image` tinyint(3) unsigned NOT NULL,
  `flash` tinyint(3) unsigned NOT NULL,
  `youtube` tinyint(3) unsigned NOT NULL,
  `internal_image` tinyint(3) unsigned NOT NULL,
  `gbif_image` tinyint(3) unsigned NOT NULL,
  `content_level` tinyint(3) unsigned NOT NULL,
  `image_object_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`hierarchy_entry_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `hierarchies_resources` (
  `resource_id` int(10) unsigned NOT NULL,
  `hierarchy_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`resource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `hierarchy_entries` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `identifier` varchar(255) character set ascii NOT NULL,
  `remote_id` varchar(255) character set ascii NOT NULL,
  `name_id` int(10) unsigned NOT NULL,
  `parent_id` int(10) unsigned NOT NULL,
  `hierarchy_id` smallint(5) unsigned NOT NULL,
  `rank_id` smallint(5) unsigned NOT NULL,
  `ancestry` varchar(500) character set ascii NOT NULL,
  `lft` int(10) unsigned NOT NULL,
  `rgt` int(10) unsigned NOT NULL,
  `depth` tinyint(3) unsigned NOT NULL,
  `taxon_concept_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `name_id` (`name_id`),
  KEY `parent_id` (`parent_id`),
  KEY `hierarchy_id` (`hierarchy_id`),
  KEY `lft` (`lft`),
  KEY `taxon_concept_id` (`taxon_concept_id`)
) ENGINE=InnoDB AUTO_INCREMENT=19222829 DEFAULT CHARSET=utf8;

CREATE TABLE `hierarchy_entry_names` (
  `hierarchy_entry_id` int(10) unsigned NOT NULL,
  `italics` varchar(300) NOT NULL,
  `italics_canonical` varchar(300) NOT NULL,
  `normal` varchar(300) NOT NULL,
  `normal_canonical` varchar(300) NOT NULL,
  `common_name_en` varchar(300) NOT NULL,
  `common_name_fr` varchar(300) NOT NULL,
  PRIMARY KEY  (`hierarchy_entry_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `hierarchy_entry_relationships` (
  `hierarchy_entry_id_1` int(10) unsigned NOT NULL,
  `hierarchy_entry_id_2` int(10) unsigned NOT NULL,
  `relationship` varchar(30) NOT NULL,
  `score` double NOT NULL,
  `extra` text NOT NULL,
  PRIMARY KEY  (`hierarchy_entry_id_1`,`hierarchy_entry_id_2`),
  KEY `score` (`score`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `info_items` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `schema_value` varchar(255) character set ascii NOT NULL,
  `label` varchar(255) NOT NULL,
  `toc_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

CREATE TABLE `item_pages` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `title_item_id` int(10) unsigned NOT NULL,
  `year` varchar(20) NOT NULL,
  `volume` varchar(20) NOT NULL,
  `issue` varchar(20) NOT NULL,
  `prefix` varchar(20) NOT NULL,
  `number` varchar(20) NOT NULL,
  `url` varchar(255) character set ascii NOT NULL,
  `page_type` varchar(20) character set ascii NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5846119 DEFAULT CHARSET=utf8;

CREATE TABLE `languages` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `label` varchar(100) NOT NULL,
  `name` varchar(100) NOT NULL,
  `iso_639_1` varchar(6) NOT NULL,
  `iso_639_2` varchar(6) NOT NULL,
  `iso_639_3` varchar(6) NOT NULL,
  `source_form` varchar(100) NOT NULL,
  `sort_order` tinyint(4) NOT NULL default '1',
  `activated_on` timestamp NULL default NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=502 DEFAULT CHARSET=utf8;

CREATE TABLE `licenses` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `title` varchar(255) NOT NULL,
  `description` varchar(400) NOT NULL,
  `source_url` varchar(255) character set ascii NOT NULL,
  `version` varchar(6) character set ascii NOT NULL,
  `logo_url` varchar(255) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `title` (`title`),
  KEY `source_url` (`source_url`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;

CREATE TABLE `mappings` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `collection_id` mediumint(8) unsigned NOT NULL,
  `name_id` int(10) unsigned NOT NULL,
  `foreign_key` varchar(600) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `name_id` (`name_id`)
) ENGINE=InnoDB AUTO_INCREMENT=57703224 DEFAULT CHARSET=utf8;

CREATE TABLE `mime_types` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `label` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8;

CREATE TABLE `name_languages` (
  `name_id` int(10) unsigned NOT NULL,
  `language_id` smallint(5) unsigned NOT NULL,
  `parent_name_id` int(10) unsigned NOT NULL,
  `preferred` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`name_id`,`language_id`,`parent_name_id`),
  KEY `parent_name_id` (`parent_name_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `names` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `namebank_id` int(10) unsigned NOT NULL,
  `string` varchar(300) NOT NULL,
  `italicized` varchar(300) NOT NULL,
  `italicized_verified` tinyint(3) unsigned NOT NULL,
  `canonical_form_id` int(10) unsigned NOT NULL,
  `canonical_verified` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `canonical_form_id` (`canonical_form_id`)
) ENGINE=InnoDB AUTO_INCREMENT=413836653 DEFAULT CHARSET=utf8;

CREATE TABLE `normalized_links` (
  `normalized_name_id` int(10) unsigned NOT NULL,
  `name_id` int(10) unsigned NOT NULL,
  `seq` tinyint(3) unsigned NOT NULL,
  `normalized_qualifier_id` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`normalized_name_id`,`name_id`),
  KEY `name_id` (`name_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `normalized_names` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name_part` varchar(100) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `name_part` (`name_part`)
) ENGINE=InnoDB AUTO_INCREMENT=1352853 DEFAULT CHARSET=utf8;

CREATE TABLE `normalized_qualifiers` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `label` varchar(50) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `page_names` (
  `item_page_id` int(10) unsigned NOT NULL,
  `name_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`name_id`,`item_page_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `publication_titles` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `marc_bib_id` varchar(40) NOT NULL,
  `marc_leader` varchar(40) NOT NULL,
  `title` varchar(300) NOT NULL,
  `short_title` varchar(300) NOT NULL,
  `details` varchar(300) NOT NULL,
  `call_number` varchar(40) NOT NULL,
  `start_year` varchar(10) NOT NULL,
  `end_year` varchar(10) NOT NULL,
  `language` varchar(10) NOT NULL,
  `author` varchar(150) NOT NULL,
  `abbreviation` varchar(150) NOT NULL,
  `url` varchar(255) character set ascii NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=699 DEFAULT CHARSET=utf8;

CREATE TABLE `random_taxa` (
  `id` int(11) NOT NULL auto_increment,
  `language_id` int(11) NOT NULL,
  `data_object_id` int(11) NOT NULL,
  `name_id` int(11) NOT NULL,
  `image_url` varchar(255) character set ascii NOT NULL,
  `thumb_url` varchar(255) character set ascii NOT NULL,
  `name` varchar(255) NOT NULL,
  `common_name_en` varchar(255) NOT NULL,
  `common_name_fr` varchar(255) NOT NULL,
  `content_level` int(11) NOT NULL,
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `taxon_concept_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_random_taxa_on_content_level` (`content_level`)
) ENGINE=InnoDB AUTO_INCREMENT=64 DEFAULT CHARSET=utf8;

CREATE TABLE `ranks` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `label` varchar(50) NOT NULL,
  `rank_group_id` smallint(6) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=562 DEFAULT CHARSET=utf8;

CREATE TABLE `ref_identifier_types` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `label` varchar(50) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;

CREATE TABLE `ref_identifiers` (
  `ref_id` int(10) unsigned NOT NULL,
  `ref_identifier_type_id` smallint(5) unsigned NOT NULL,
  `identifier` varchar(255) character set ascii NOT NULL,
  PRIMARY KEY  (`ref_id`,`ref_identifier_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `refs` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `full_reference` varchar(400) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `refs_taxa` (
  `taxon_id` int(10) unsigned NOT NULL,
  `ref_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`taxon_id`,`ref_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `resource_agent_roles` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `label` varchar(100) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;

CREATE TABLE `resource_statuses` (
  `id` int(11) NOT NULL auto_increment,
  `label` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;

CREATE TABLE `resources` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `title` varchar(255) NOT NULL,
  `accesspoint_url` varchar(255) default NULL,
  `metadata_url` varchar(255) default NULL,
  `service_type_id` int(11) NOT NULL default '1',
  `service_version` varchar(255) default NULL,
  `resource_set_code` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  `logo_url` varchar(255) default NULL,
  `language_id` smallint(5) unsigned default NULL,
  `subject` varchar(255) NOT NULL,
  `bibliographic_citation` varchar(400) default NULL,
  `license_id` tinyint(3) unsigned NOT NULL,
  `rights_statement` varchar(400) default NULL,
  `rights_holder` varchar(255) default NULL,
  `refresh_period_hours` smallint(5) unsigned default NULL,
  `resource_modified_at` datetime default NULL,
  `resource_created_at` datetime default NULL,
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `harvested_at` datetime default NULL,
  `dataset_file_name` varchar(255) default NULL,
  `dataset_content_type` varchar(255) default NULL,
  `dataset_file_size` int(11) default NULL,
  `resource_status_id` int(11) default NULL,
  `auto_publish` tinyint(1) NOT NULL default '0',
  `vetted` tinyint(1) NOT NULL default '0',
  `notes` text,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;

CREATE TABLE `resources_taxa` (
  `resource_id` int(10) unsigned NOT NULL,
  `taxon_id` int(10) unsigned NOT NULL,
  `identifier` varchar(255) character set ascii NOT NULL,
  `source_url` varchar(255) character set ascii NOT NULL,
  `taxon_created_at` timestamp NOT NULL default '0000-00-00 00:00:00',
  `taxon_modified_at` timestamp NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`resource_id`,`taxon_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `service_types` (
  `id` smallint(6) NOT NULL auto_increment,
  `label` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

CREATE TABLE `statuses` (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `label` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `synonym_relations` (
  `id` smallint(6) NOT NULL auto_increment,
  `label` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8;

CREATE TABLE `synonyms` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name_id` int(10) unsigned NOT NULL,
  `synonym_relation_id` tinyint(3) unsigned NOT NULL,
  `language_id` smallint(5) unsigned NOT NULL,
  `hierarchy_entry_id` int(10) unsigned NOT NULL,
  `preferred` tinyint(3) unsigned NOT NULL,
  `hierarchy_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `hierarchy_entry_id` (`hierarchy_entry_id`)
) ENGINE=InnoDB AUTO_INCREMENT=132320 DEFAULT CHARSET=utf8;

CREATE TABLE `table_of_contents` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `parent_id` smallint(5) unsigned NOT NULL,
  `label` varchar(255) NOT NULL,
  `view_order` smallint(5) unsigned default '0',
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=298 DEFAULT CHARSET=utf8;

CREATE TABLE `taxa` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `guid` varchar(32) character set ascii NOT NULL,
  `taxon_kingdom` varchar(255) NOT NULL,
  `taxon_phylum` varchar(255) NOT NULL,
  `taxon_class` varchar(255) NOT NULL,
  `taxon_order` varchar(255) NOT NULL,
  `taxon_family` varchar(255) NOT NULL,
  `scientific_name` varchar(255) NOT NULL,
  `name_id` int(10) unsigned NOT NULL,
  `hierarchy_entry_id` int(10) unsigned NOT NULL,
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`id`),
  KEY `name_id` (`name_id`)
) ENGINE=InnoDB AUTO_INCREMENT=888012 DEFAULT CHARSET=utf8;

CREATE TABLE `taxon_concept_content` (
  `taxon_concept_id` int(10) unsigned NOT NULL,
  `text` tinyint(3) unsigned NOT NULL,
  `image` tinyint(3) unsigned NOT NULL,
  `child_image` tinyint(3) unsigned NOT NULL,
  `flash` tinyint(3) unsigned NOT NULL,
  `youtube` tinyint(3) unsigned NOT NULL,
  `internal_image` tinyint(3) unsigned NOT NULL,
  `gbif_image` tinyint(3) unsigned NOT NULL,
  `content_level` tinyint(3) unsigned NOT NULL,
  `image_object_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`taxon_concept_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `taxon_concept_names` (
  `taxon_concept_id` int(10) unsigned NOT NULL,
  `name_id` int(10) unsigned NOT NULL,
  `source_hierarchy_entry_id` int(10) unsigned NOT NULL,
  `language_id` int(10) unsigned NOT NULL,
  `vern` tinyint(3) unsigned NOT NULL,
  `preferred` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`taxon_concept_id`,`name_id`,`source_hierarchy_entry_id`,`language_id`),
  KEY `vern` (`vern`),
  KEY `name_id` (`name_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `taxon_concept_relationships` (
  `taxon_concept_id_1` int(10) unsigned NOT NULL,
  `taxon_concept_id_2` int(10) unsigned NOT NULL,
  `relationship` varchar(30) NOT NULL,
  `score` double NOT NULL,
  `extra` text NOT NULL,
  PRIMARY KEY  (`taxon_concept_id_1`,`taxon_concept_id_2`),
  KEY `score` (`score`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `taxon_concepts` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `supercedure_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=261 DEFAULT CHARSET=utf8;

CREATE TABLE `title_items` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `publication_title_id` int(10) unsigned NOT NULL,
  `bar_code` varchar(50) NOT NULL,
  `marc_item_id` varchar(50) NOT NULL,
  `call_number` varchar(100) NOT NULL,
  `volume_info` varchar(100) NOT NULL,
  `url` varchar(255) character set ascii NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13855 DEFAULT CHARSET=utf8;

CREATE TABLE `top_images` (
  `hierarchy_entry_id` int(10) unsigned NOT NULL,
  `data_object_id` int(10) unsigned NOT NULL,
  `view_order` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`hierarchy_entry_id`,`data_object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `top_unpublished_images` (
  `hierarchy_entry_id` int(10) unsigned NOT NULL,
  `data_object_id` int(10) unsigned NOT NULL,
  `data_rating` float NOT NULL,
  `vetted_id` tinyint(3) unsigned NOT NULL,
  `visibility_id` int(11) default NULL,
  `published` tinyint(1) NOT NULL default '0',
  `curated` tinyint(1) NOT NULL default '0',
  `view_order` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`hierarchy_entry_id`,`data_object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `vetted` (
  `id` int(11) NOT NULL auto_increment,
  `label` varchar(255) default '',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

CREATE TABLE `visibilities` (
  `id` int(11) NOT NULL auto_increment,
  `label` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

