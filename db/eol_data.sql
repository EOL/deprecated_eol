-- MySQL dump 10.11
--
-- Host: localhost    Database: eol_data_production
-- ------------------------------------------------------
-- Server version	5.0.74-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `agent_contact_roles`
--

DROP TABLE IF EXISTS `agent_contact_roles`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agent_contact_roles` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `label` varchar(100) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agent_contacts`
--

DROP TABLE IF EXISTS `agent_contacts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
) ENGINE=InnoDB AUTO_INCREMENT=125 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agent_data_types`
--

DROP TABLE IF EXISTS `agent_data_types`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agent_data_types` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `label` varchar(100) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agent_provided_data_types`
--

DROP TABLE IF EXISTS `agent_provided_data_types`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agent_provided_data_types` (
  `agent_data_type_id` int(10) unsigned NOT NULL,
  `agent_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`agent_data_type_id`,`agent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agent_roles`
--

DROP TABLE IF EXISTS `agent_roles`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agent_roles` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `label` varchar(100) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agent_statuses`
--

DROP TABLE IF EXISTS `agent_statuses`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agent_statuses` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `label` varchar(100) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agents`
--

DROP TABLE IF EXISTS `agents`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
) ENGINE=InnoDB AUTO_INCREMENT=12264 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agents_data_objects`
--

DROP TABLE IF EXISTS `agents_data_objects`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agents_data_objects` (
  `data_object_id` int(10) unsigned NOT NULL,
  `agent_id` int(10) unsigned NOT NULL,
  `agent_role_id` tinyint(3) unsigned NOT NULL,
  `view_order` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`data_object_id`,`agent_id`,`agent_role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agents_hierarchy_entries`
--

DROP TABLE IF EXISTS `agents_hierarchy_entries`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agents_hierarchy_entries` (
  `hierarchy_entry_id` int(10) unsigned NOT NULL,
  `agent_id` int(10) unsigned NOT NULL,
  `agent_role_id` tinyint(3) unsigned NOT NULL,
  `view_order` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`hierarchy_entry_id`,`agent_id`,`agent_role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agents_resources`
--

DROP TABLE IF EXISTS `agents_resources`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agents_resources` (
  `agent_id` int(10) unsigned NOT NULL,
  `resource_id` int(10) unsigned NOT NULL,
  `resource_agent_role_id` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`agent_id`,`resource_id`,`resource_agent_role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `agents_synonyms`
--

DROP TABLE IF EXISTS `agents_synonyms`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agents_synonyms` (
  `synonym_id` int(10) unsigned NOT NULL,
  `agent_id` int(10) unsigned NOT NULL,
  `agent_role_id` tinyint(3) unsigned NOT NULL,
  `view_order` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`synonym_id`,`agent_id`,`agent_role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `audiences`
--

DROP TABLE IF EXISTS `audiences`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `audiences` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `label` varchar(100) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `audiences_data_objects`
--

DROP TABLE IF EXISTS `audiences_data_objects`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `audiences_data_objects` (
  `data_object_id` int(10) unsigned NOT NULL,
  `audience_id` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`data_object_id`,`audience_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `canonical_forms`
--

DROP TABLE IF EXISTS `canonical_forms`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `canonical_forms` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `string` varchar(300) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `string` (`string`(255))
) ENGINE=InnoDB AUTO_INCREMENT=5610775 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `clean_names`
--

DROP TABLE IF EXISTS `clean_names`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `clean_names` (
  `name_id` int(10) unsigned NOT NULL,
  `clean_name` varchar(300) character set utf8 collate utf8_bin NOT NULL,
  PRIMARY KEY  (`name_id`),
  KEY `clean_name` (`clean_name`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `collection_types`
--

DROP TABLE IF EXISTS `collection_types`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `collection_types` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `parent_id` int(11) NOT NULL,
  `lft` smallint(5) unsigned default NULL,
  `rgt` smallint(5) unsigned default NULL,
  `label` varchar(300) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `parent_id` (`parent_id`),
  KEY `lft` (`lft`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `collection_types_collections`
--

DROP TABLE IF EXISTS `collection_types_collections`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `collection_types_collections` (
  `collection_type_id` smallint(5) unsigned NOT NULL,
  `collection_id` mediumint(8) unsigned NOT NULL,
  PRIMARY KEY  (`collection_type_id`,`collection_id`),
  KEY `collection_id` (`collection_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `collections`
--

DROP TABLE IF EXISTS `collections`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `collections` (
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
) ENGINE=InnoDB AUTO_INCREMENT=15502 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `common_names`
--

DROP TABLE IF EXISTS `common_names`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `common_names` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `common_name` varchar(255) NOT NULL,
  `language_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `common_name` (`common_name`)
) ENGINE=InnoDB AUTO_INCREMENT=91061 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `common_names_taxa`
--

DROP TABLE IF EXISTS `common_names_taxa`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `common_names_taxa` (
  `taxon_id` int(10) unsigned NOT NULL,
  `common_name_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`taxon_id`,`common_name_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `content_partner_agreements`
--

DROP TABLE IF EXISTS `content_partner_agreements`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
) ENGINE=InnoDB AUTO_INCREMENT=69 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `content_partners`
--

DROP TABLE IF EXISTS `content_partners`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
  `show_mou_on_partner_page` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=115 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `data_objects`
--

DROP TABLE IF EXISTS `data_objects`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
  `description_linked` text,
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
  `data_rating` float NOT NULL default '2.5',
  `vetted_id` tinyint(3) unsigned NOT NULL,
  `visibility_id` int(11) default NULL,
  `published` tinyint(1) NOT NULL default '0',
  `curated` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `data_type_id` (`data_type_id`),
  KEY `index_data_objects_on_visibility_id` (`visibility_id`),
  KEY `index_data_objects_on_guid` (`guid`),
  KEY `index_data_objects_on_published` (`published`),
  KEY `object_url` (`object_url`)
) ENGINE=InnoDB AUTO_INCREMENT=2055862 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `data_objects_harvest_events`
--

DROP TABLE IF EXISTS `data_objects_harvest_events`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `data_objects_harvest_events` (
  `harvest_event_id` int(10) unsigned NOT NULL,
  `data_object_id` int(10) unsigned NOT NULL,
  `guid` varchar(32) character set ascii NOT NULL,
  `status_id` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`harvest_event_id`,`data_object_id`),
  KEY `index_data_objects_harvest_events_on_guid` (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `data_objects_info_items`
--

DROP TABLE IF EXISTS `data_objects_info_items`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `data_objects_info_items` (
  `data_object_id` int(10) unsigned NOT NULL,
  `info_item_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`data_object_id`,`info_item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `data_objects_refs`
--

DROP TABLE IF EXISTS `data_objects_refs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `data_objects_refs` (
  `data_object_id` int(10) unsigned NOT NULL,
  `ref_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`data_object_id`,`ref_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `data_objects_table_of_contents`
--

DROP TABLE IF EXISTS `data_objects_table_of_contents`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `data_objects_table_of_contents` (
  `data_object_id` int(10) unsigned NOT NULL,
  `toc_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`data_object_id`,`toc_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `data_objects_taxa`
--

DROP TABLE IF EXISTS `data_objects_taxa`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `data_objects_taxa` (
  `taxon_id` int(10) unsigned NOT NULL,
  `data_object_id` int(10) unsigned NOT NULL,
  `identifier` varchar(255) character set ascii NOT NULL,
  PRIMARY KEY  (`taxon_id`,`data_object_id`),
  KEY `data_object_id` (`data_object_id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `data_objects_untrust_reasons`
--

DROP TABLE IF EXISTS `data_objects_untrust_reasons`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `data_objects_untrust_reasons` (
  `id` int(11) NOT NULL auto_increment,
  `data_object_id` int(11) default NULL,
  `untrust_reason_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `data_types`
--

DROP TABLE IF EXISTS `data_types`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `data_types` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `schema_value` varchar(255) character set ascii NOT NULL,
  `label` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `harvest_events`
--

DROP TABLE IF EXISTS `harvest_events`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `harvest_events` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `resource_id` varchar(100) character set ascii NOT NULL,
  `began_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `completed_at` timestamp NULL default NULL,
  `published_at` timestamp NULL default NULL,
  PRIMARY KEY  (`id`),
  KEY `resource_id` (`resource_id`)
) ENGINE=InnoDB AUTO_INCREMENT=610 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `harvest_events_taxa`
--

DROP TABLE IF EXISTS `harvest_events_taxa`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `harvest_events_taxa` (
  `harvest_event_id` int(10) unsigned NOT NULL,
  `taxon_id` int(10) unsigned NOT NULL,
  `guid` varchar(32) character set ascii NOT NULL,
  `status_id` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`harvest_event_id`,`taxon_id`),
  KEY `taxon_id` (`taxon_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `hierarchies`
--

DROP TABLE IF EXISTS `hierarchies`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hierarchies` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL,
  `label` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `indexed_on` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `hierarchy_group_id` int(10) unsigned NOT NULL,
  `hierarchy_group_version` tinyint(3) unsigned NOT NULL,
  `url` varchar(255) character set ascii NOT NULL,
  `browsable` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=398 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `hierarchies_content`
--

DROP TABLE IF EXISTS `hierarchies_content`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `hierarchies_content_test`
--

DROP TABLE IF EXISTS `hierarchies_content_test`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hierarchies_content_test` (
  `hierarchy_entry_id` int(10) unsigned NOT NULL,
  `text` tinyint(3) unsigned NOT NULL,
  `text_unpublished` tinyint(3) unsigned NOT NULL,
  `image` tinyint(3) unsigned NOT NULL,
  `image_unpublished` tinyint(3) unsigned NOT NULL,
  `child_image` tinyint(3) unsigned NOT NULL,
  `child_image_unpublished` tinyint(3) unsigned NOT NULL,
  `video` tinyint(3) unsigned NOT NULL,
  `video_unpublished` tinyint(3) unsigned NOT NULL,
  `map` tinyint(3) unsigned NOT NULL,
  `map_unpublished` tinyint(3) unsigned NOT NULL,
  `content_level` tinyint(3) unsigned NOT NULL,
  `image_object_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`hierarchy_entry_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `hierarchies_resources`
--

DROP TABLE IF EXISTS `hierarchies_resources`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hierarchies_resources` (
  `resource_id` int(10) unsigned NOT NULL,
  `hierarchy_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`resource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `hierarchy_entries`
--

DROP TABLE IF EXISTS `hierarchy_entries`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hierarchy_entries` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `identifier` varchar(255) character set ascii NOT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=27916185 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `hierarchy_entries_saved`
--

DROP TABLE IF EXISTS `hierarchy_entries_saved`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hierarchy_entries_saved` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `identifier` varchar(255) character set ascii NOT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=20622641 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `hierarchy_entry_names`
--

DROP TABLE IF EXISTS `hierarchy_entry_names`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `hierarchy_entry_relationships`
--

DROP TABLE IF EXISTS `hierarchy_entry_relationships`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `hierarchy_entry_relationships` (
  `hierarchy_entry_id_1` int(10) unsigned NOT NULL,
  `hierarchy_entry_id_2` int(10) unsigned NOT NULL,
  `relationship` varchar(30) NOT NULL,
  `score` double NOT NULL,
  `extra` text NOT NULL,
  PRIMARY KEY  (`hierarchy_entry_id_1`,`hierarchy_entry_id_2`),
  KEY `score` (`score`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `info_items`
--

DROP TABLE IF EXISTS `info_items`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `info_items` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `schema_value` varchar(255) character set ascii NOT NULL,
  `label` varchar(255) NOT NULL,
  `toc_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `item_pages`
--

DROP TABLE IF EXISTS `item_pages`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
) ENGINE=InnoDB AUTO_INCREMENT=6766912 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `languages`
--

DROP TABLE IF EXISTS `languages`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
) ENGINE=InnoDB AUTO_INCREMENT=783 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `licenses`
--

DROP TABLE IF EXISTS `licenses`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `licenses` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `title` varchar(255) NOT NULL,
  `description` varchar(400) NOT NULL,
  `source_url` varchar(255) character set ascii NOT NULL,
  `version` varchar(6) character set ascii NOT NULL,
  `logo_url` varchar(255) character set ascii NOT NULL,
  `show_to_content_partners` tinyint(1) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `title` (`title`),
  KEY `source_url` (`source_url`)
) ENGINE=InnoDB AUTO_INCREMENT=39 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `mappings`
--

DROP TABLE IF EXISTS `mappings`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `mappings` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `collection_id` mediumint(8) unsigned NOT NULL,
  `name_id` int(10) unsigned NOT NULL,
  `foreign_key` varchar(600) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `name_id` (`name_id`),
  KEY `collection_id` (`collection_id`)
) ENGINE=InnoDB AUTO_INCREMENT=26153895 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `mime_types`
--

DROP TABLE IF EXISTS `mime_types`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `mime_types` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `label` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `name_languages`
--

DROP TABLE IF EXISTS `name_languages`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `name_languages` (
  `name_id` int(10) unsigned NOT NULL,
  `language_id` smallint(5) unsigned NOT NULL,
  `parent_name_id` int(10) unsigned NOT NULL,
  `preferred` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`name_id`,`language_id`,`parent_name_id`),
  KEY `parent_name_id` (`parent_name_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `names`
--

DROP TABLE IF EXISTS `names`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
) ENGINE=InnoDB AUTO_INCREMENT=12665194 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `normalized_links`
--

DROP TABLE IF EXISTS `normalized_links`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `normalized_links` (
  `normalized_name_id` int(10) unsigned NOT NULL,
  `name_id` int(10) unsigned NOT NULL,
  `seq` tinyint(3) unsigned NOT NULL,
  `normalized_qualifier_id` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`normalized_name_id`,`name_id`),
  KEY `name_id` (`name_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `normalized_names`
--

DROP TABLE IF EXISTS `normalized_names`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `normalized_names` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name_part` varchar(100) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `name_part` (`name_part`)
) ENGINE=InnoDB AUTO_INCREMENT=2572096 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `normalized_qualifiers`
--

DROP TABLE IF EXISTS `normalized_qualifiers`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `normalized_qualifiers` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `label` varchar(50) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `page_names`
--

DROP TABLE IF EXISTS `page_names`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `page_names` (
  `item_page_id` int(10) unsigned NOT NULL,
  `name_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`name_id`,`item_page_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `page_stats_dataobjects`
--

DROP TABLE IF EXISTS `page_stats_dataobjects`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `page_stats_dataobjects` (
  `id` int(11) NOT NULL auto_increment,
  `active` varchar(1) default 'n',
  `taxa_count` int(11) default NULL,
  `vetted_unknown_published_visible_uniqueGuid` int(11) default NULL,
  `vetted_untrusted_published_visible_uniqueGuid` int(11) default NULL,
  `vetted_unknown_published_notVisible_uniqueGuid` int(11) default NULL,
  `vetted_untrusted_published_notVisible_uniqueGuid` int(11) default NULL,
  `date_created` date default NULL,
  `time_created` time default NULL,
  `timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `a_vetted_unknown_published_visible_uniqueGuid` longtext,
  `a_vetted_untrusted_published_visible_uniqueGuid` longtext,
  `a_vetted_unknown_published_notVisible_uniqueGuid` longtext,
  `a_vetted_untrusted_published_notVisible_uniqueGuid` longtext,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=70 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `page_stats_marine`
--

DROP TABLE IF EXISTS `page_stats_marine`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `page_stats_marine` (
  `id` int(11) NOT NULL auto_increment,
  `active` tinyint(1) default '0',
  `names_from_xml` int(11) default NULL,
  `names_in_eol` int(11) default NULL,
  `marine_pages` int(11) default NULL,
  `pages_with_objects` int(11) default NULL,
  `pages_with_vetted_objects` int(11) default NULL,
  `date_created` date default NULL,
  `time_created` time default NULL,
  `timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `page_stats_taxa`
--

DROP TABLE IF EXISTS `page_stats_taxa`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `page_stats_taxa` (
  `id` int(11) NOT NULL auto_increment,
  `active` varchar(1) default 'n',
  `taxa_count` int(11) default NULL,
  `taxa_text` int(11) default NULL,
  `taxa_images` int(11) default NULL,
  `taxa_text_images` int(11) default NULL,
  `taxa_BHL_no_text` int(11) default NULL,
  `taxa_links_no_text` int(11) default NULL,
  `taxa_images_no_text` int(11) default NULL,
  `taxa_text_no_images` int(11) default NULL,
  `vet_obj_only_1cat_inCOL` int(11) default NULL,
  `vet_obj_only_1cat_notinCOL` int(11) default NULL,
  `vet_obj_morethan_1cat_inCOL` int(11) default NULL,
  `vet_obj_morethan_1cat_notinCOL` int(11) default NULL,
  `vet_obj` int(11) default NULL,
  `no_vet_obj2` int(11) default NULL,
  `with_BHL` int(11) default NULL,
  `vetted_not_published` int(11) default NULL,
  `vetted_unknown_published_visible_inCol` int(11) default NULL,
  `vetted_unknown_published_visible_notinCol` int(11) default NULL,
  `date_created` date default NULL,
  `time_created` time default NULL,
  `pages_incol` int(11) default NULL,
  `pages_not_incol` int(11) default NULL,
  `a_taxa_with_text` longtext,
  `timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `a_vetted_not_published` longtext,
  `a_vetted_unknown_published_visible_notinCol` longtext,
  `a_vetted_unknown_published_visible_inCol` longtext,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=68 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `publication_titles`
--

DROP TABLE IF EXISTS `publication_titles`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
) ENGINE=InnoDB AUTO_INCREMENT=7209 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `random_hierarchy_images`
--

DROP TABLE IF EXISTS `random_hierarchy_images`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `random_hierarchy_images` (
  `id` int(11) NOT NULL auto_increment,
  `data_object_id` int(11) NOT NULL,
  `hierarchy_entry_id` int(11) default NULL,
  `hierarchy_id` int(11) default NULL,
  `taxon_concept_id` int(11) default NULL,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `hierarchy_entry_id` (`hierarchy_entry_id`),
  KEY `hierarchy_id` (`hierarchy_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2120515 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `random_taxa`
--

DROP TABLE IF EXISTS `random_taxa`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
) ENGINE=InnoDB AUTO_INCREMENT=16451634 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `ranks`
--

DROP TABLE IF EXISTS `ranks`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ranks` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `label` varchar(50) NOT NULL,
  `rank_group_id` smallint(6) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=572 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `ref_identifier_types`
--

DROP TABLE IF EXISTS `ref_identifier_types`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ref_identifier_types` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `label` varchar(50) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `ref_identifiers`
--

DROP TABLE IF EXISTS `ref_identifiers`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ref_identifiers` (
  `ref_id` int(10) unsigned NOT NULL,
  `ref_identifier_type_id` smallint(5) unsigned NOT NULL,
  `identifier` varchar(255) character set ascii NOT NULL,
  PRIMARY KEY  (`ref_id`,`ref_identifier_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `refs`
--

DROP TABLE IF EXISTS `refs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `refs` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `full_reference` varchar(400) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `full_reference` (`full_reference`(255))
) ENGINE=InnoDB AUTO_INCREMENT=742912 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `refs_taxa`
--

DROP TABLE IF EXISTS `refs_taxa`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `refs_taxa` (
  `taxon_id` int(10) unsigned NOT NULL,
  `ref_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`taxon_id`,`ref_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `resource_agent_roles`
--

DROP TABLE IF EXISTS `resource_agent_roles`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `resource_agent_roles` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `label` varchar(100) character set ascii NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `resource_statuses`
--

DROP TABLE IF EXISTS `resource_statuses`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `resource_statuses` (
  `id` int(11) NOT NULL auto_increment,
  `label` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `resources`
--

DROP TABLE IF EXISTS `resources`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
) ENGINE=InnoDB AUTO_INCREMENT=69 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `resources_taxa`
--

DROP TABLE IF EXISTS `resources_taxa`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `resources_taxa` (
  `resource_id` int(10) unsigned NOT NULL,
  `taxon_id` int(10) unsigned NOT NULL,
  `identifier` varchar(255) character set ascii NOT NULL,
  `source_url` varchar(255) character set ascii NOT NULL,
  `taxon_created_at` timestamp NOT NULL default '0000-00-00 00:00:00',
  `taxon_modified_at` timestamp NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`resource_id`,`taxon_id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `service_types`
--

DROP TABLE IF EXISTS `service_types`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `service_types` (
  `id` smallint(6) NOT NULL auto_increment,
  `label` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `statuses`
--

DROP TABLE IF EXISTS `statuses`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `statuses` (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `label` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `synonym_relations`
--

DROP TABLE IF EXISTS `synonym_relations`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `synonym_relations` (
  `id` smallint(6) NOT NULL auto_increment,
  `label` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=45 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `synonyms`
--

DROP TABLE IF EXISTS `synonyms`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `synonyms` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name_id` int(10) unsigned NOT NULL,
  `synonym_relation_id` tinyint(3) unsigned NOT NULL,
  `language_id` smallint(5) unsigned NOT NULL,
  `hierarchy_entry_id` int(10) unsigned NOT NULL,
  `preferred` tinyint(3) unsigned NOT NULL,
  `hierarchy_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `hierarchy_entry_id` (`hierarchy_entry_id`),
  KEY `name_id` (`name_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3102564 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `table_of_contents`
--

DROP TABLE IF EXISTS `table_of_contents`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `table_of_contents` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `parent_id` smallint(5) unsigned NOT NULL,
  `label` varchar(255) NOT NULL,
  `view_order` smallint(5) unsigned default '0',
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=299 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `taxa`
--

DROP TABLE IF EXISTS `taxa`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
) ENGINE=InnoDB AUTO_INCREMENT=2482504 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `taxon_concept_content`
--

DROP TABLE IF EXISTS `taxon_concept_content`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `taxon_concept_content_test`
--

DROP TABLE IF EXISTS `taxon_concept_content_test`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `taxon_concept_content_test` (
  `taxon_concept_id` int(10) unsigned NOT NULL,
  `text` tinyint(3) unsigned NOT NULL,
  `text_unpublished` tinyint(3) unsigned NOT NULL,
  `image` tinyint(3) unsigned NOT NULL,
  `image_unpublished` tinyint(3) unsigned NOT NULL,
  `child_image` tinyint(3) unsigned NOT NULL,
  `child_image_unpublished` tinyint(3) unsigned NOT NULL,
  `video` tinyint(3) unsigned NOT NULL,
  `video_unpublished` tinyint(3) unsigned NOT NULL,
  `map` tinyint(3) unsigned NOT NULL,
  `map_unpublished` tinyint(3) unsigned NOT NULL,
  `content_level` tinyint(3) unsigned NOT NULL,
  `image_object_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`taxon_concept_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `taxon_concept_names`
--

DROP TABLE IF EXISTS `taxon_concept_names`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `taxon_concept_names` (
  `taxon_concept_id` int(10) unsigned NOT NULL,
  `name_id` int(10) unsigned NOT NULL,
  `source_hierarchy_entry_id` int(10) unsigned NOT NULL,
  `language_id` int(10) unsigned NOT NULL,
  `vern` tinyint(3) unsigned NOT NULL,
  `preferred` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`taxon_concept_id`,`name_id`,`source_hierarchy_entry_id`,`language_id`),
  KEY `vern` (`vern`),
  KEY `name_id` (`name_id`),
  KEY `source_hierarchy_entry_id` (`source_hierarchy_entry_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `taxon_concept_names_saved`
--

DROP TABLE IF EXISTS `taxon_concept_names_saved`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `taxon_concept_names_saved` (
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
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `taxon_concept_relationships`
--

DROP TABLE IF EXISTS `taxon_concept_relationships`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `taxon_concept_relationships` (
  `taxon_concept_id_1` int(10) unsigned NOT NULL,
  `taxon_concept_id_2` int(10) unsigned NOT NULL,
  `relationship` varchar(30) NOT NULL,
  `score` double NOT NULL,
  `extra` text NOT NULL,
  PRIMARY KEY  (`taxon_concept_id_1`,`taxon_concept_id_2`),
  KEY `score` (`score`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `taxon_concepts`
--

DROP TABLE IF EXISTS `taxon_concepts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `taxon_concepts` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `supercedure_id` int(10) unsigned NOT NULL,
  `vetted_id` tinyint(3) unsigned NOT NULL default '0',
  `published` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `published` (`published`),
  KEY `supercedure_id` (`supercedure_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10209628 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `taxon_concepts_saved`
--

DROP TABLE IF EXISTS `taxon_concepts_saved`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `taxon_concepts_saved` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `supercedure_id` int(10) unsigned NOT NULL,
  `vetted_id` tinyint(3) unsigned NOT NULL default '0',
  `published` tinyint(3) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1809448 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `title_items`
--

DROP TABLE IF EXISTS `title_items`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `title_items` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `publication_title_id` int(10) unsigned NOT NULL,
  `bar_code` varchar(50) NOT NULL,
  `marc_item_id` varchar(50) NOT NULL,
  `call_number` varchar(100) NOT NULL,
  `volume_info` varchar(100) NOT NULL,
  `url` varchar(255) character set ascii NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=30854 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `top_images`
--

DROP TABLE IF EXISTS `top_images`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `top_images` (
  `hierarchy_entry_id` int(10) unsigned NOT NULL,
  `data_object_id` int(10) unsigned NOT NULL,
  `view_order` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`hierarchy_entry_id`,`data_object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `top_unpublished_images`
--

DROP TABLE IF EXISTS `top_unpublished_images`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `top_unpublished_images` (
  `hierarchy_entry_id` int(10) unsigned NOT NULL,
  `data_object_id` int(10) unsigned NOT NULL,
  `view_order` smallint(5) unsigned NOT NULL,
  PRIMARY KEY  (`hierarchy_entry_id`,`data_object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `untrust_reasons`
--

DROP TABLE IF EXISTS `untrust_reasons`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `untrust_reasons` (
  `id` int(11) NOT NULL auto_increment,
  `label` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `vetted`
--

DROP TABLE IF EXISTS `vetted`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `vetted` (
  `id` int(11) NOT NULL auto_increment,
  `label` varchar(255) default '',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `visibilities`
--

DROP TABLE IF EXISTS `visibilities`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `visibilities` (
  `id` int(11) NOT NULL auto_increment,
  `label` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-08-20 15:54:25
