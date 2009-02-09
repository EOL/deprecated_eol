-- MySQL dump 10.11
--
-- Host: localhost    Database: eol_data_development_rails
-- ------------------------------------------------------
-- Server version	5.0.67

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='For content partner agent_contacts';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='For content partners';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='For content partners';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='For content partners';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Identifies how agent is linked to data_object';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Agents are content partners and used for object attribution';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Agents are associated with data objects in various roles';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Agents are associated with hierarchy entries in various roles';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Agents are associated with resources in various roles';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Agents are associated with synonyms in various roles';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Controlled list for determining the "expertise" of a data object';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='A data object can have zero to many target audiences';
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `canonical_forms`
--

DROP TABLE IF EXISTS `canonical_forms`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `canonical_forms` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `string` varchar(300) NOT NULL COMMENT 'a canonical form of a scientific name is the name parts without authorship, rank information, or anthing except the latinized name parts. These are for the most part algorithmically generated',
  PRIMARY KEY  (`id`),
  KEY `string` (`string`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Every name string has one canonical form - a simplified version of the string';
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `clean_names`
--

DROP TABLE IF EXISTS `clean_names`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `clean_names` (
  `name_id` int(10) unsigned NOT NULL,
  `clean_name` varchar(300) character set utf8 collate utf8_bin NOT NULL COMMENT 'there is a one to one reltaionship between a name string and a clean name. The clean name takes the string and lowercases it (uncluding diacriticals), removes leading/trailing whitespace, removes some punctuation (periods and more), and pads remaining punctuation with spaces.',
  PRIMARY KEY  (`name_id`),
  KEY `clean_name` (`clean_name`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Every name string as one clean name - a different simplified version of the string';
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `collections`
--

DROP TABLE IF EXISTS `collections`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `collections` (
  `id` mediumint(8) unsigned NOT NULL auto_increment,
  `agent_id` int(10) unsigned NOT NULL COMMENT 'our internal id of the project being linked to. Projects can have many collections - usually grouped by a theme (The mammals of X, The images of X, Species pages from X...)',
  `title` varchar(150) NOT NULL COMMENT 'title of the collection of links for this project',
  `description` varchar(300) NOT NULL COMMENT 'description of this collection of links to',
  `uri` varchar(255) character set ascii NOT NULL COMMENT 'a base uri used to generate full uris when combined with mapping foreign keys. Often these will look something like http://site.org/id=FOREIGNKEY. The middleware will substitute FOREIGNKEY with foreignkey from mappings. This was designed as such to save DB space when storing millions of outlinks.',
  `link` varchar(255) character set ascii NOT NULL COMMENT 'a link back to a descriptive page for this collection',
  `logo_url` varchar(255) character set ascii NOT NULL,
  `vetted` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Collections define projects which EOL links to using mappings. Websites may have several collections of different themes.';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Used only to cache common names supplied by content partners through their resources';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='links a resources common names with its taxa';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `data_objects`
--

DROP TABLE IF EXISTS `data_objects`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `data_objects` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `guid` varchar(32) character set ascii NOT NULL COMMENT 'this guid is generated by EOL. A 32 character hexadecimal',
  `data_type_id` smallint(5) unsigned NOT NULL,
  `mime_type_id` smallint(5) unsigned NOT NULL,
  `object_title` varchar(255) NOT NULL COMMENT 'a string title for the object. Generally not used for images',
  `language_id` smallint(5) unsigned NOT NULL,
  `license_id` tinyint(3) unsigned NOT NULL,
  `rights_statement` varchar(300) NOT NULL COMMENT 'a brief statement of the copyright protection for this object',
  `rights_holder` varchar(255) NOT NULL COMMENT 'a string stating the owner of copyright for this object',
  `bibliographic_citation` varchar(300) NOT NULL COMMENT 'a string stating how this object should be subsequently cited. Provided by the contributor of the resource',
  `source_url` varchar(255) character set ascii NOT NULL COMMENT 'a url where users are to be redirected to learn more about this data object',
  `description` text NOT NULL,
  `object_url` varchar(255) character set ascii NOT NULL COMMENT 'recommended; the url which resolves to this data object. Generally used only for images, video, and other multimedia',
  `object_cache_url` bigint(20) unsigned default NULL COMMENT 'an integer representation of the EOL local cache of the object. For example, a value may be 200902090812345 - that will be split by middleware into the parts 2009/02/09/08/12345 which represents the storage directory structure. The directory structure represents year/month/day/hour/unique_id',
  `thumbnail_url` varchar(255) character set ascii NOT NULL COMMENT 'not required; the url which resolves to a thumbnail representation of this object. Generally used only for images, video, and other multimedia',
  `thumbnail_cache_url` bigint(20) unsigned default NULL COMMENT 'an integer representation of the EOL local cache of the thumbnail',
  `location` varchar(255) NOT NULL,
  `latitude` double NOT NULL COMMENT 'the latitude at which the object was first collected/captured. We have no standard way of represdenting this. Usually measured in decimal values, but could also be degrees',
  `longitude` double NOT NULL COMMENT 'the longitude at which the object was first collected/captured',
  `altitude` double NOT NULL COMMENT 'the altitude at which the object was first collected/captured',
  `object_created_at` timestamp NOT NULL default '0000-00-00 00:00:00' COMMENT 'date when the object was originally created. Information contained within the resource',
  `object_modified_at` timestamp NOT NULL default '0000-00-00 00:00:00' COMMENT 'date when the object was last modified. Information contained within the resource',
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP COMMENT 'date when the object was added to the EOL index',
  `updated_at` timestamp NOT NULL default '0000-00-00 00:00:00' COMMENT 'date when the object was last modified within the EOL index. This should pretty much always equal the created_at date, therefore is likely not necessary',
  `data_rating` float NOT NULL COMMENT 'a float value representing the quality of the object. The lower the value the higher the quality. The idea is to sort each data type by their data_rating in ascending order which will show the best ones first',
  `vetted_id` tinyint(3) unsigned NOT NULL,
  `visibility_id` int(11) default NULL,
  `published` tinyint(1) NOT NULL default '0' COMMENT 'required; boolean; set to 1 if the object is currently published',
  `curated` tinyint(1) NOT NULL default '0' COMMENT 'required; boolean; set to 1 if the object has ever been curated',
  PRIMARY KEY  (`id`),
  KEY `data_type_id` (`data_type_id`),
  KEY `index_data_objects_on_visibility_id` (`visibility_id`),
  KEY `index_data_objects_on_guid` (`guid`),
  KEY `index_data_objects_on_published` (`published`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
  KEY `data_object_id` (`data_object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `harvest_events`
--

DROP TABLE IF EXISTS `harvest_events`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `harvest_events` (
  `id` tinyint(3) unsigned NOT NULL auto_increment,
  `resource_id` varchar(100) character set ascii NOT NULL,
  `began_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `completed_at` timestamp NULL default NULL,
  `published_at` timestamp NULL default NULL,
  PRIMARY KEY  (`id`),
  KEY `resource_id` (`resource_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
  PRIMARY KEY  (`harvest_event_id`,`taxon_id`)
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
  `agent_id` int(10) unsigned NOT NULL COMMENT 'recommended; our internal id of the source agent responsible for the entire hierarchy',
  `label` varchar(255) NOT NULL COMMENT 'recommended; succinct title for the hierarchy (e.g. Catalogue of Life: Annual Checklist 2009)',
  `description` text NOT NULL COMMENT 'not required; a more verbose description describing the hierarchy. Could be a paragraph describing what it is and what it contains',
  `indexed_on` timestamp NOT NULL default CURRENT_TIMESTAMP COMMENT 'required; the date which we created and indexed the hierarchy',
  `hierarchy_group_id` int(10) unsigned NOT NULL COMMENT 'not required; there is no hierarchy_groups table, but this field was meant to identify hierarchies of the same source so they can be verioned and older versions retained but not presented',
  `hierarchy_group_version` tinyint(3) unsigned NOT NULL COMMENT 'not required; this is mean to uniquely identify hierarchies within the same group. This version number has been an internal incrementing value',
  `url` varchar(255) character set ascii NOT NULL COMMENT 'not required; a link back to a web page describing this hierarchy',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='A container for hierarchy_entries. These are usually taxonomic hierarchies, but can be general collections of assertions about taxa.';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Summarizes the data types available to a given hierarchy entry. Also lists its content level and the data_object_id of the first displayed image.';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='NEWER: Summarizes the data types available to a given hierarchy entry. Also lists its content level and the data_object_id of the first displayed image.';
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
  `identifier` varchar(255) character set ascii NOT NULL COMMENT 'recommended; a unique id from the provider for this node',
  `remote_id` varchar(255) character set ascii NOT NULL COMMENT 'this is no longer used and should be removed',
  `name_id` int(10) unsigned NOT NULL COMMENT 'recommended; the name string for this node. It is possible that nodes have no names, but most of the time they will',
  `parent_id` int(10) unsigned NOT NULL COMMENT 'recommended; the parent_id references the hierarchy_entry_id of the parent of this node. Used to create trees. Root nodes will have a partent_id of 0',
  `hierarchy_id` smallint(5) unsigned NOT NULL COMMENT 'required; the id of the container hierarchy',
  `rank_id` smallint(5) unsigned NOT NULL COMMENT 'recommended; when available, this is the id of the rank string which defines the taxonomic rank of the node',
  `ancestry` varchar(500) character set ascii NOT NULL COMMENT 'not required; perhaps now obsolete. Used to store the materialized path of this node\'s ancestors',
  `lft` int(10) unsigned NOT NULL COMMENT 'required; the left value of this node within the hierarchy\'s nested set',
  `rgt` int(10) unsigned NOT NULL COMMENT 'required; the right value of this node within the hierarchy\'s nested set',
  `depth` tinyint(3) unsigned NOT NULL COMMENT 'recommended; the depth of this node in within the hierarchy\'s tree',
  `taxon_concept_id` int(10) unsigned NOT NULL COMMENT 'required; the id of the taxon_concept described by this hierarchy_entry',
  PRIMARY KEY  (`id`),
  KEY `name_id` (`name_id`),
  KEY `parent_id` (`parent_id`),
  KEY `hierarchy_id` (`hierarchy_id`),
  KEY `lft` (`lft`),
  KEY `taxon_concept_id` (`taxon_concept_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='This table is now likely obsolete';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Used for BHL. The publication items have many pages';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `mappings`
--

DROP TABLE IF EXISTS `mappings`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `mappings` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `collection_id` mediumint(8) unsigned NOT NULL COMMENT 'required; the id of the container collection',
  `name_id` int(10) unsigned NOT NULL COMMENT 'required; the id of the name as it appears in the external project',
  `foreign_key` varchar(600) character set ascii NOT NULL COMMENT 'recommended; the unique identifier of this taxon in the project being linked to',
  PRIMARY KEY  (`id`),
  KEY `name_id` (`name_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Contents of a collection - outlinks to external projects';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Type of data object. Controlled list used in the EOL schema';
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `name_languages`
--

DROP TABLE IF EXISTS `name_languages`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `name_languages` (
  `name_id` int(10) unsigned NOT NULL,
  `language_id` smallint(5) unsigned NOT NULL COMMENT 'required; the language of the string. \'Scientific name\' is a language',
  `parent_name_id` int(10) unsigned NOT NULL COMMENT 'not required; associated a common name or surrogate with its proper scientific name',
  `preferred` tinyint(3) unsigned NOT NULL COMMENT 'not required; identifies if the common names is preferred for the given scientific name in the given language',
  PRIMARY KEY  (`name_id`,`language_id`,`parent_name_id`),
  KEY `parent_name_id` (`parent_name_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Used mainly to identify which names are scientific names, and to link up common names';
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `names`
--

DROP TABLE IF EXISTS `names`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `names` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `namebank_id` int(10) unsigned NOT NULL COMMENT 'required; this identifies the uBio NameBank id for this string so that we can stay in sync. Many newer names will have this set to 0 as it is unknown if the name is in NameBank',
  `string` varchar(300) NOT NULL COMMENT 'the actual name. This is unique - every unique sequence of characters has one and only one name_id (we should probably add a unique index to this field)',
  `italicized` varchar(300) NOT NULL COMMENT 'required; this includes html <i> tags in the proper place to display the string in its italicized form. Generally only species and subspecific names are italizied. Usually algorithmically generated',
  `italicized_verified` tinyint(3) unsigned NOT NULL COMMENT 'required; if an editor verifies the italicized form is correct, or corrects it, this should be set to 1 so it is not algorithmically replaced if we change the algorithm',
  `canonical_form_id` int(10) unsigned NOT NULL COMMENT 'required; every name string has a canonical form',
  `canonical_verified` tinyint(3) unsigned NOT NULL COMMENT 'required; same as with italicized form, if an editor verifies the canonical form we want to maintin their edits if we were to redo the canonical form algorithm',
  PRIMARY KEY  (`id`),
  KEY `canonical_form_id` (`canonical_form_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT 'Represents the name of a taxon';
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
  `seq` tinyint(3) unsigned NOT NULL COMMENT 'the position index of this word in the string',
  `normalized_qualifier_id` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`normalized_name_id`,`name_id`),
  KEY `name_id` (`name_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Joins name strings with their atomized single word parts. Used for efficient substring searching';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Gives identifiers to the atomized single word parts of name strings';
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `normalized_qualifiers`
--

DROP TABLE IF EXISTS `normalized_qualifiers`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `normalized_qualifiers` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `label` varchar(50) NOT NULL COMMENT 'Possible qualifiers: name, author, year',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Identifies the role the name part plays in the larger name string';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Used for BHL. Links name strings to BHL page identifiers. Many names on a given page';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Used for BHL. The main publications';
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `random_taxa`
--

DROP TABLE IF EXISTS `random_taxa`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `random_taxa` (
  `id` int(11) NOT NULL auto_increment COMMENT 'an auto_inc field - a random primary key for this table - used for randomization',
  `language_id` int(11) NOT NULL,
  `data_object_id` int(11) NOT NULL COMMENT 'the data_object_id of the preferred image of this taxon',
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Includes vetted taxa with images in a random order';
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
  `rank_group_id` smallint(6) NOT NULL COMMENT 'not required; there is no rank_groups table. This is used to group (reconcile) different strings for the same rank',
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Stores taxonomic ranks. Used in hierarchy_entries';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
  `full_reference` varchar(400) NOT NULL COMMENT 'required; references are stored as full strings - they are not atomized into their pieces (title, author, year...)',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Stores reference full strings. References are linked to data objects and taxa.';
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
  `label` varchar(100) character set ascii NOT NULL COMMENT 'required; possible labels include data supplier, technical contact, data host, systems administrator',
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='The role an agent plays in the provision of a resource';
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `resource_statuses`
--

DROP TABLE IF EXISTS `resource_statuses`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `resource_statuses` (
  `id` int(11) NOT NULL auto_increment,
  `label` varchar(255) default NULL COMMENT 'required; possible labels include uploading, uploaded, validated...',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='The status of the resource in harvesting';
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
  `accesspoint_url` varchar(255) default NULL COMMENT 'recommended; the url where the resource can be accessed. Not used when the resource is a file which was uploaded',
  `metadata_url` varchar(255) default NULL,
  `service_type_id` int(11) NOT NULL default '1' COMMENT 'recommended; if accesspoint_url is defined, this will indicate what kind of protocal can be expected to be found there. (this is perhaps misued right now)',
  `service_version` varchar(255) default NULL,
  `resource_set_code` varchar(255) default NULL COMMENT 'not required; if the resource contains several subsets (such as DiGIR providers) theis indicates the set we are to harvest',
  `description` varchar(255) default NULL,
  `logo_url` varchar(255) default NULL,
  `language_id` smallint(5) unsigned default NULL COMMENT 'not required; the default language of the contents of the resource',
  `subject` varchar(255) NOT NULL,
  `bibliographic_citation` varchar(400) default NULL COMMENT 'not required; the default bibliographic citation for all data objects whithin the resource',
  `license_id` tinyint(3) unsigned NOT NULL,
  `rights_statement` varchar(400) default NULL,
  `rights_holder` varchar(255) default NULL,
  `refresh_period_hours` smallint(5) unsigned default NULL COMMENT 'recommended; if the resource is to be harvested regularly, this field indicates how frequent the updates are',
  `resource_modified_at` datetime default NULL,
  `resource_created_at` datetime default NULL,
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `harvested_at` datetime default NULL COMMENT 'required; this field is updated each time the resource is harvested',
  `dataset_file_name` varchar(255) default NULL,
  `dataset_content_type` varchar(255) default NULL,
  `dataset_file_size` int(11) default NULL,
  `resource_status_id` int(11) default NULL,
  `auto_publish` tinyint(1) NOT NULL default '0' COMMENT 'required; boolean; indicates whether the resource is to be published immediately after harvesting',
  `vetted` tinyint(1) NOT NULL default '0',
  `notes` text,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Content parters supply resource files which contain data objects and taxa';
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
  PRIMARY KEY  (`resource_id`,`taxon_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Perhaps is obsolete now that we have harvest_events and harvest_events_taxa';
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `service_types`
--

DROP TABLE IF EXISTS `service_types`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `service_types` (
  `id` smallint(6) NOT NULL auto_increment,
  `label` varchar(255) NOT NULL COMMENT 'possible labels include DiGIR, TAPIR, BioCASE, .xml, .tar, .gzip...',
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='What type of protocol the content partners are exposing';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Generic status table designed to be used in several places. Now only used in harvest_event tables';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
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
  `synonym_relation_id` tinyint(3) unsigned NOT NULL COMMENT 'the relationship this synonym has with the preferred name for this node',
  `language_id` smallint(5) unsigned NOT NULL COMMENT 'generally only set when the synonym is a common name',
  `hierarchy_entry_id` int(10) unsigned NOT NULL COMMENT 'associated node in the hierarchy',
  `preferred` tinyint(3) unsigned NOT NULL COMMENT 'set to 1 if this is a common name and is the preferred common name for the node in its language',
  `hierarchy_id` smallint(5) unsigned NOT NULL COMMENT 'this is redundant as it can be found via the synonym\'s hierarchy_entry. I think its here for legacy reasons, but we can probably get rid of it',
  PRIMARY KEY  (`id`),
  KEY `hierarchy_entry_id` (`hierarchy_entry_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Used to assigned taxonomic synonyms and common names to hierarchy entries';
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `table_of_contents`
--

DROP TABLE IF EXISTS `table_of_contents`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `table_of_contents` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `parent_id` smallint(5) unsigned NOT NULL COMMENT 'refers to the parent taxon_of_contents id. Our table of content is only two levels deep',
  `label` varchar(255) NOT NULL,
  `view_order` smallint(5) unsigned default '0' COMMENT 'used to organize the view of the table of contents on the species page in order of priority, not alphabetically',
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `taxa`
--

DROP TABLE IF EXISTS `taxa`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `taxa` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `guid` varchar(32) character set ascii NOT NULL COMMENT 'this guid is generated by EOL. A 32 character hexadecimal',
  `taxon_kingdom` varchar(255) NOT NULL,
  `taxon_phylum` varchar(255) NOT NULL,
  `taxon_class` varchar(255) NOT NULL,
  `taxon_order` varchar(255) NOT NULL,
  `taxon_family` varchar(255) NOT NULL,
  `scientific_name` varchar(255) NOT NULL,
  `name_id` int(10) unsigned NOT NULL COMMENT 'the id of the string corresponding with this taxon\'s scientific name. If the scientific name of this taxon doesn\'t exist one will be created',
  `hierarchy_entry_id` int(10) unsigned NOT NULL COMMENT 'each taxon in this table will be associated with a hierarchy entry created specifically for the associated resource',
  `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`id`),
  KEY `name_id` (`name_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='For taxa definitions coming from content partner\'s resources';
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
  `source_hierarchy_entry_id` int(10) unsigned NOT NULL COMMENT 'recommended; if the name came from a certain hierarchy entry or its associated synonyms, the id of the entry will be listed here. This can be used to track down the source or attribution for a given name',
  `language_id` int(10) unsigned NOT NULL,
  `vern` tinyint(3) unsigned NOT NULL COMMENT 'boolean; if this is a common name, set this field to 1',
  `preferred` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY  (`taxon_concept_id`,`name_id`,`source_hierarchy_entry_id`,`language_id`),
  KEY `vern` (`vern`),
  KEY `name_id` (`name_id`),
  KEY `source_hierarchy_entry_id` (`source_hierarchy_entry_id`)
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
  `relationship` varchar(30) NOT NULL COMMENT 'possible relationships would be equivalent, broader than, narrower than...',
  `score` double NOT NULL COMMENT 'the confidence in this assertion. Between 0 and 1, 1 being 100% confidence',
  `extra` text NOT NULL,
  PRIMARY KEY  (`taxon_concept_id_1`,`taxon_concept_id_2`),
  KEY `score` (`score`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Used by the algorithm to group taxon concepts';
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `taxon_concepts`
--

DROP TABLE IF EXISTS `taxon_concepts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `taxon_concepts` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `supercedure_id` int(10) unsigned NOT NULL COMMENT 'if concepts are at first thought to be distinct, there will be two concepts with two different ids. When they are confirmed to be the same one will be superceded by the other, and that replacement is kept track of so that older URLs can be redirected to the proper ids',
  `vetted_id` tinyint(3) unsigned NOT NULL default '0' COMMENT 'some concepts come from untrusted resources and are left untrusted until the resources become trusted',
  `published` tinyint(3) unsigned NOT NULL default '0' COMMENT 'some concepts come from resource left unpublished until the resource becomes published',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='This table is poorly named. Used to group similar hierarchy entries';
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
  `url` varchar(255) character set ascii NOT NULL COMMENT 'url for the description page for this item',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Used for BHL. Publications can have different volumes, versions, etc.';
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `top_images`
--

DROP TABLE IF EXISTS `top_images`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `top_images` (
  `hierarchy_entry_id` int(10) unsigned NOT NULL,
  `data_object_id` int(10) unsigned NOT NULL COMMENT 'data object id of the image',
  `view_order` smallint(5) unsigned NOT NULL COMMENT 'order in which to show the images, lower values shown first',
  PRIMARY KEY  (`hierarchy_entry_id`,`data_object_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='caches the top 300 or so best images for a particular hierarchy entry';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='cache the top 300 or so images which are unpublished - for curators and content partners';
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `vetted`
--

DROP TABLE IF EXISTS `vetted`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `vetted` (
  `id` int(11) NOT NULL auto_increment,
  `label` varchar(255) default '' COMMENT 'possible labels are trusted, untrusted, unknown...',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vetted statuses';
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-01-15 21:10:32
