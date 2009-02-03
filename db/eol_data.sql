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
  `id` tinyint(3) unsigned NOT NULL auto_increment COMMENT 'primary key',
  `label` varchar(100) character set ascii NOT NULL COMMENT 'a label!',
  PRIMARY KEY  (`id`),
  KEY `label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 
COMMENT 'i am the agent contact roles table';
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `agent_contact_roles`
--

LOCK TABLES `agent_contact_roles` WRITE;
/*!40000 ALTER TABLE `agent_contact_roles` DISABLE KEYS */;
INSERT INTO `agent_contact_roles` VALUES (2,'Administrative Contact'),(1,'Primary Contact'),(3,'Technical Contact');
/*!40000 ALTER TABLE `agent_contact_roles` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `agent_contacts`
--

LOCK TABLES `agent_contacts` WRITE;
/*!40000 ALTER TABLE `agent_contacts` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_contacts` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `agent_data_types`
--

LOCK TABLES `agent_data_types` WRITE;
/*!40000 ALTER TABLE `agent_data_types` DISABLE KEYS */;
INSERT INTO `agent_data_types` VALUES (1,'Audio'),(2,'Image'),(3,'Text'),(4,'Video');
/*!40000 ALTER TABLE `agent_data_types` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `agent_provided_data_types`
--

LOCK TABLES `agent_provided_data_types` WRITE;
/*!40000 ALTER TABLE `agent_provided_data_types` DISABLE KEYS */;
/*!40000 ALTER TABLE `agent_provided_data_types` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `agent_roles`
--

LOCK TABLES `agent_roles` WRITE;
/*!40000 ALTER TABLE `agent_roles` DISABLE KEYS */;
INSERT INTO `agent_roles` VALUES (1,'Animator'),(2,'Author'),(3,'Compiler'),(4,'Composer'),(5,'Creator'),(6,'Director'),(7,'Editor'),(8,'Illustrator'),(9,'Photographer'),(10,'Project'),(11,'Publisher'),(12,'Recorder'),(13,'Source');
/*!40000 ALTER TABLE `agent_roles` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `agent_statuses`
--

LOCK TABLES `agent_statuses` WRITE;
/*!40000 ALTER TABLE `agent_statuses` DISABLE KEYS */;
INSERT INTO `agent_statuses` VALUES (2,'Active'),(3,'Archived'),(1,'Pending');
/*!40000 ALTER TABLE `agent_statuses` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `agents`
--

LOCK TABLES `agents` WRITE;
/*!40000 ALTER TABLE `agents` DISABLE KEYS */;
/*!40000 ALTER TABLE `agents` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `agents_data_objects`
--

LOCK TABLES `agents_data_objects` WRITE;
/*!40000 ALTER TABLE `agents_data_objects` DISABLE KEYS */;
/*!40000 ALTER TABLE `agents_data_objects` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `agents_hierarchy_entries`
--

LOCK TABLES `agents_hierarchy_entries` WRITE;
/*!40000 ALTER TABLE `agents_hierarchy_entries` DISABLE KEYS */;
/*!40000 ALTER TABLE `agents_hierarchy_entries` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `agents_resources`
--

LOCK TABLES `agents_resources` WRITE;
/*!40000 ALTER TABLE `agents_resources` DISABLE KEYS */;
/*!40000 ALTER TABLE `agents_resources` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `agents_synonyms`
--

LOCK TABLES `agents_synonyms` WRITE;
/*!40000 ALTER TABLE `agents_synonyms` DISABLE KEYS */;
/*!40000 ALTER TABLE `agents_synonyms` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `audiences`
--

LOCK TABLES `audiences` WRITE;
/*!40000 ALTER TABLE `audiences` DISABLE KEYS */;
INSERT INTO `audiences` VALUES (3,'Children'),(1,'Expert users'),(2,'General public');
/*!40000 ALTER TABLE `audiences` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `audiences_data_objects`
--

LOCK TABLES `audiences_data_objects` WRITE;
/*!40000 ALTER TABLE `audiences_data_objects` DISABLE KEYS */;
/*!40000 ALTER TABLE `audiences_data_objects` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `canonical_forms`
--

LOCK TABLES `canonical_forms` WRITE;
/*!40000 ALTER TABLE `canonical_forms` DISABLE KEYS */;
/*!40000 ALTER TABLE `canonical_forms` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `clean_names`
--

LOCK TABLES `clean_names` WRITE;
/*!40000 ALTER TABLE `clean_names` DISABLE KEYS */;
/*!40000 ALTER TABLE `clean_names` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `collections`
--

DROP TABLE IF EXISTS `collections`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `collections`
--

LOCK TABLES `collections` WRITE;
/*!40000 ALTER TABLE `collections` DISABLE KEYS */;
/*!40000 ALTER TABLE `collections` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `common_names`
--

LOCK TABLES `common_names` WRITE;
/*!40000 ALTER TABLE `common_names` DISABLE KEYS */;
/*!40000 ALTER TABLE `common_names` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `common_names_taxa`
--

LOCK TABLES `common_names_taxa` WRITE;
/*!40000 ALTER TABLE `common_names_taxa` DISABLE KEYS */;
/*!40000 ALTER TABLE `common_names_taxa` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `content_partner_agreements`
--

LOCK TABLES `content_partner_agreements` WRITE;
/*!40000 ALTER TABLE `content_partner_agreements` DISABLE KEYS */;
/*!40000 ALTER TABLE `content_partner_agreements` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `content_partners`
--

LOCK TABLES `content_partners` WRITE;
/*!40000 ALTER TABLE `content_partners` DISABLE KEYS */;
/*!40000 ALTER TABLE `content_partners` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `data_objects`
--

LOCK TABLES `data_objects` WRITE;
/*!40000 ALTER TABLE `data_objects` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_objects` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `data_objects_harvest_events`
--

LOCK TABLES `data_objects_harvest_events` WRITE;
/*!40000 ALTER TABLE `data_objects_harvest_events` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_objects_harvest_events` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `data_objects_info_items`
--

LOCK TABLES `data_objects_info_items` WRITE;
/*!40000 ALTER TABLE `data_objects_info_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_objects_info_items` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `data_objects_refs`
--

LOCK TABLES `data_objects_refs` WRITE;
/*!40000 ALTER TABLE `data_objects_refs` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_objects_refs` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `data_objects_table_of_contents`
--

LOCK TABLES `data_objects_table_of_contents` WRITE;
/*!40000 ALTER TABLE `data_objects_table_of_contents` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_objects_table_of_contents` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `data_objects_taxa`
--

LOCK TABLES `data_objects_taxa` WRITE;
/*!40000 ALTER TABLE `data_objects_taxa` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_objects_taxa` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `data_types`
--

LOCK TABLES `data_types` WRITE;
/*!40000 ALTER TABLE `data_types` DISABLE KEYS */;
INSERT INTO `data_types` VALUES (1,'http://purl.org/dc/dcmitype/StillImage','Image'),(2,'http://purl.org/dc/dcmitype/Sound','Sound'),(3,'http://purl.org/dc/dcmitype/Text','Text'),(4,'http://purl.org/dc/dcmitype/MovingImage','Video');
/*!40000 ALTER TABLE `data_types` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `harvest_events`
--

LOCK TABLES `harvest_events` WRITE;
/*!40000 ALTER TABLE `harvest_events` DISABLE KEYS */;
/*!40000 ALTER TABLE `harvest_events` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `harvest_events_taxa`
--

LOCK TABLES `harvest_events_taxa` WRITE;
/*!40000 ALTER TABLE `harvest_events_taxa` DISABLE KEYS */;
/*!40000 ALTER TABLE `harvest_events_taxa` ENABLE KEYS */;
UNLOCK TABLES;

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
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hierarchies`
--

LOCK TABLES `hierarchies` WRITE;
/*!40000 ALTER TABLE `hierarchies` DISABLE KEYS */;
/*!40000 ALTER TABLE `hierarchies` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `hierarchies_content`
--

LOCK TABLES `hierarchies_content` WRITE;
/*!40000 ALTER TABLE `hierarchies_content` DISABLE KEYS */;
/*!40000 ALTER TABLE `hierarchies_content` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `hierarchies_content_test`
--

LOCK TABLES `hierarchies_content_test` WRITE;
/*!40000 ALTER TABLE `hierarchies_content_test` DISABLE KEYS */;
/*!40000 ALTER TABLE `hierarchies_content_test` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `hierarchies_resources`
--

LOCK TABLES `hierarchies_resources` WRITE;
/*!40000 ALTER TABLE `hierarchies_resources` DISABLE KEYS */;
/*!40000 ALTER TABLE `hierarchies_resources` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hierarchy_entries`
--

DROP TABLE IF EXISTS `hierarchy_entries`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `hierarchy_entries`
--

LOCK TABLES `hierarchy_entries` WRITE;
/*!40000 ALTER TABLE `hierarchy_entries` DISABLE KEYS */;
/*!40000 ALTER TABLE `hierarchy_entries` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `hierarchy_entry_names`
--

LOCK TABLES `hierarchy_entry_names` WRITE;
/*!40000 ALTER TABLE `hierarchy_entry_names` DISABLE KEYS */;
/*!40000 ALTER TABLE `hierarchy_entry_names` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `hierarchy_entry_relationships`
--

LOCK TABLES `hierarchy_entry_relationships` WRITE;
/*!40000 ALTER TABLE `hierarchy_entry_relationships` DISABLE KEYS */;
/*!40000 ALTER TABLE `hierarchy_entry_relationships` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `info_items`
--

LOCK TABLES `info_items` WRITE;
/*!40000 ALTER TABLE `info_items` DISABLE KEYS */;
INSERT INTO `info_items` VALUES (1,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Associations','Associations',0),(2,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Behaviour','Behaviour',0),(3,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#ConservationStatus','ConservationStatus',0),(4,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Cyclicity','Cyclicity',0),(5,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Cytology','Cytology',0),(6,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#DiagnosticDescription','DiagnosticDescription',0),(7,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Diseases','Diseases',0),(8,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Dispersal','Dispersal',0),(9,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Distribution','Distribution',0),(10,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Evolution','Evolution',0),(11,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#GeneralDescription','GeneralDescription',0),(12,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Genetics','Genetics',0),(13,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Growth','Growth',0),(14,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Habitat','Habitat',0),(15,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Legislation','Legislation',0),(16,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LifeCycle','LifeCycle',0),(17,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LifeExpectancy','LifeExpectancy',0),(18,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LookAlikes','LookAlikes',0),(19,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Management','Management',0),(20,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Migration','Migration',0),(21,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#MolecularBiology','MolecularBiology',0),(22,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Morphology','Morphology',0),(23,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Physiology','Physiology',0),(24,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#PopulationBiology','PopulationBiology',0),(25,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Procedures','Procedures',0),(26,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Reproduction','Reproduction',0),(27,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#RiskStatement','RiskStatement',0),(28,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Size','Size',0),(29,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#TaxonBiology','TaxonBiology',0),(30,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Threats','Threats',0),(31,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Trends','Trends',0),(32,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#TrophicStrategy','TrophicStrategy',0),(33,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Uses','Uses',0);
/*!40000 ALTER TABLE `info_items` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `item_pages`
--

LOCK TABLES `item_pages` WRITE;
/*!40000 ALTER TABLE `item_pages` DISABLE KEYS */;
/*!40000 ALTER TABLE `item_pages` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB AUTO_INCREMENT=502 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `languages`
--

LOCK TABLES `languages` WRITE;
/*!40000 ALTER TABLE `languages` DISABLE KEYS */;
INSERT INTO `languages` VALUES (1,'','English','en','','','',1,'2008-01-01 05:00:00'),(2,'','Francais','fr','','','',2,'2008-01-01 05:00:00'),(3,'','Deutsch','de','','','',3,'2008-01-01 05:00:00'),(4,'','Russian','ru','','','',4,'2008-01-01 05:00:00'),(5,'','Ukrainian','ua','','','',5,'2008-01-01 05:00:00'),(501,'','','scient','','','',1,NULL);
/*!40000 ALTER TABLE `languages` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `licenses`
--

LOCK TABLES `licenses` WRITE;
/*!40000 ALTER TABLE `licenses` DISABLE KEYS */;
INSERT INTO `licenses` VALUES (1,'public domain','No rights reserved','','0','',1),(2,'all rights reserved','&#169; All rights reserved','','0','',0),(3,'cc-by-nc 3.0','Some rights reserved','http://creativecommons.org/licenses/by-nc/3.0/','0','/images/licenses/cc_by_nc_small.png',1),(4,'cc-by 3.0','Some rights reserved','http://creativecommons.org/licenses/by/3.0/','0','/images/licenses/cc_by_small.png',1),(5,'cc-by-sa 3.0','Some rights reserved','http://creativecommons.org/licenses/by-sa/3.0/','0','/images/licenses/cc_by_sa_small.png',1),(6,'cc-by-nc-sa 3.0','Some rights reserved','http://creativecommons.org/licenses/by-nc-sa/3.0/','0','/images/licenses/cc_by_nc_sa_small.png',1),(7,'gnu-fdl','Some rights reserved','http://www.gnu.org/licenses/fdl.html','0','/images/licenses/gnu_fdl_small.png',0),(8,'gnu-gpl','Some rights reserved','http://www.gnu.org/licenses/gpl.html','0','/images/licenses/gnu_fdl_small.png',0),(9,'no license','The material cannot be licensed','','0','',0);
/*!40000 ALTER TABLE `licenses` ENABLE KEYS */;
UNLOCK TABLES;

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
  KEY `name_id` (`name_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `mappings`
--

LOCK TABLES `mappings` WRITE;
/*!40000 ALTER TABLE `mappings` DISABLE KEYS */;
/*!40000 ALTER TABLE `mappings` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `mime_types`
--

LOCK TABLES `mime_types` WRITE;
/*!40000 ALTER TABLE `mime_types` DISABLE KEYS */;
INSERT INTO `mime_types` VALUES (1,'audio/mpeg'),(2,'audio/x-ms-wma'),(3,'audio/x-pn-realaudio'),(4,'audio/x-realaudio'),(5,'audio/x-wav'),(6,'image/bmp'),(7,'image/gif'),(8,'image/jpeg'),(9,'image/png'),(10,'image/svg+xml'),(11,'image/tiff'),(12,'text/html'),(13,'text/plain'),(14,'text/richtext'),(15,'text/rtf'),(16,'text/xml'),(17,'video/mp4'),(18,'video/mpeg'),(19,'video/quicktime'),(20,'video/x-flv'),(21,'video/x-ms-wmv');
/*!40000 ALTER TABLE `mime_types` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `name_languages`
--

LOCK TABLES `name_languages` WRITE;
/*!40000 ALTER TABLE `name_languages` DISABLE KEYS */;
/*!40000 ALTER TABLE `name_languages` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `names`
--

LOCK TABLES `names` WRITE;
/*!40000 ALTER TABLE `names` DISABLE KEYS */;
/*!40000 ALTER TABLE `names` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `normalized_links`
--

LOCK TABLES `normalized_links` WRITE;
/*!40000 ALTER TABLE `normalized_links` DISABLE KEYS */;
/*!40000 ALTER TABLE `normalized_links` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `normalized_names`
--

LOCK TABLES `normalized_names` WRITE;
/*!40000 ALTER TABLE `normalized_names` DISABLE KEYS */;
/*!40000 ALTER TABLE `normalized_names` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `normalized_qualifiers`
--

LOCK TABLES `normalized_qualifiers` WRITE;
/*!40000 ALTER TABLE `normalized_qualifiers` DISABLE KEYS */;
INSERT INTO `normalized_qualifiers` VALUES (1,'Name'),(2,'Author'),(3,'Year');
/*!40000 ALTER TABLE `normalized_qualifiers` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `page_names`
--

LOCK TABLES `page_names` WRITE;
/*!40000 ALTER TABLE `page_names` DISABLE KEYS */;
/*!40000 ALTER TABLE `page_names` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `publication_titles`
--

LOCK TABLES `publication_titles` WRITE;
/*!40000 ALTER TABLE `publication_titles` DISABLE KEYS */;
/*!40000 ALTER TABLE `publication_titles` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `random_taxa`
--

LOCK TABLES `random_taxa` WRITE;
/*!40000 ALTER TABLE `random_taxa` DISABLE KEYS */;
/*!40000 ALTER TABLE `random_taxa` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `ranks`
--

LOCK TABLES `ranks` WRITE;
/*!40000 ALTER TABLE `ranks` DISABLE KEYS */;
/*!40000 ALTER TABLE `ranks` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `ref_identifier_types`
--

LOCK TABLES `ref_identifier_types` WRITE;
/*!40000 ALTER TABLE `ref_identifier_types` DISABLE KEYS */;
INSERT INTO `ref_identifier_types` VALUES (1,'bici'),(2,'coden'),(3,'doi'),(4,'eissn'),(5,'handle'),(7,'isbn'),(6,'issn'),(8,'lsid'),(9,'oclc'),(10,'sici'),(11,'url'),(12,'urn');
/*!40000 ALTER TABLE `ref_identifier_types` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `ref_identifiers`
--

LOCK TABLES `ref_identifiers` WRITE;
/*!40000 ALTER TABLE `ref_identifiers` DISABLE KEYS */;
/*!40000 ALTER TABLE `ref_identifiers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `refs`
--

DROP TABLE IF EXISTS `refs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `refs` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `full_reference` varchar(400) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `refs`
--

LOCK TABLES `refs` WRITE;
/*!40000 ALTER TABLE `refs` DISABLE KEYS */;
/*!40000 ALTER TABLE `refs` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `refs_taxa`
--

LOCK TABLES `refs_taxa` WRITE;
/*!40000 ALTER TABLE `refs_taxa` DISABLE KEYS */;
/*!40000 ALTER TABLE `refs_taxa` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `resource_agent_roles`
--

LOCK TABLES `resource_agent_roles` WRITE;
/*!40000 ALTER TABLE `resource_agent_roles` DISABLE KEYS */;
INSERT INTO `resource_agent_roles` VALUES (6,'Administrative'),(1,'Data Administrator'),(4,'Data Host'),(3,'Data Supplier'),(2,'System Administrator'),(5,'Technical Host');
/*!40000 ALTER TABLE `resource_agent_roles` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `resource_statuses`
--

LOCK TABLES `resource_statuses` WRITE;
/*!40000 ALTER TABLE `resource_statuses` DISABLE KEYS */;
INSERT INTO `resource_statuses` VALUES (1,'Uploading','2009-01-15 21:06:53','2009-01-15 21:06:53'),(2,'Uploaded','2009-01-15 21:06:53','2009-01-15 21:06:53'),(3,'Upload Failed','2009-01-15 21:06:53','2009-01-15 21:06:53'),(4,'Moved to Content Server','2009-01-15 21:06:53','2009-01-15 21:06:53'),(5,'Validated','2009-01-15 21:06:53','2009-01-15 21:06:53'),(6,'Validation Failed','2009-01-15 21:06:53','2009-01-15 21:06:53'),(7,'Being Processed','2009-01-15 21:06:53','2009-01-15 21:06:53'),(8,'Processed','2009-01-15 21:06:53','2009-01-15 21:06:53'),(9,'Processing Failed','2009-01-15 21:06:53','2009-01-15 21:06:53'),(10,'Published','2009-01-15 21:06:53','2009-01-15 21:06:53');
/*!40000 ALTER TABLE `resource_statuses` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `resources`
--

LOCK TABLES `resources` WRITE;
/*!40000 ALTER TABLE `resources` DISABLE KEYS */;
/*!40000 ALTER TABLE `resources` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `resources_taxa`
--

LOCK TABLES `resources_taxa` WRITE;
/*!40000 ALTER TABLE `resources_taxa` DISABLE KEYS */;
/*!40000 ALTER TABLE `resources_taxa` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `service_types`
--

LOCK TABLES `service_types` WRITE;
/*!40000 ALTER TABLE `service_types` DISABLE KEYS */;
INSERT INTO `service_types` VALUES (1,'EOL Transfer Schema');
/*!40000 ALTER TABLE `service_types` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `statuses`
--

LOCK TABLES `statuses` WRITE;
/*!40000 ALTER TABLE `statuses` DISABLE KEYS */;
INSERT INTO `statuses` VALUES (1,'Inserted'),(3,'Unchanged'),(2,'Updated');
/*!40000 ALTER TABLE `statuses` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `synonym_relations`
--

LOCK TABLES `synonym_relations` WRITE;
/*!40000 ALTER TABLE `synonym_relations` DISABLE KEYS */;
/*!40000 ALTER TABLE `synonym_relations` ENABLE KEYS */;
UNLOCK TABLES;

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
  KEY `hierarchy_entry_id` (`hierarchy_entry_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `synonyms`
--

LOCK TABLES `synonyms` WRITE;
/*!40000 ALTER TABLE `synonyms` DISABLE KEYS */;
/*!40000 ALTER TABLE `synonyms` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `table_of_contents`
--

LOCK TABLES `table_of_contents` WRITE;
/*!40000 ALTER TABLE `table_of_contents` DISABLE KEYS */;
/*!40000 ALTER TABLE `table_of_contents` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `taxa`
--

LOCK TABLES `taxa` WRITE;
/*!40000 ALTER TABLE `taxa` DISABLE KEYS */;
/*!40000 ALTER TABLE `taxa` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `taxon_concept_content`
--

LOCK TABLES `taxon_concept_content` WRITE;
/*!40000 ALTER TABLE `taxon_concept_content` DISABLE KEYS */;
/*!40000 ALTER TABLE `taxon_concept_content` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `taxon_concept_content_test`
--

LOCK TABLES `taxon_concept_content_test` WRITE;
/*!40000 ALTER TABLE `taxon_concept_content_test` DISABLE KEYS */;
/*!40000 ALTER TABLE `taxon_concept_content_test` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `taxon_concept_names`
--

LOCK TABLES `taxon_concept_names` WRITE;
/*!40000 ALTER TABLE `taxon_concept_names` DISABLE KEYS */;
/*!40000 ALTER TABLE `taxon_concept_names` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `taxon_concept_relationships`
--

LOCK TABLES `taxon_concept_relationships` WRITE;
/*!40000 ALTER TABLE `taxon_concept_relationships` DISABLE KEYS */;
/*!40000 ALTER TABLE `taxon_concept_relationships` ENABLE KEYS */;
UNLOCK TABLES;

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
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `taxon_concepts`
--

LOCK TABLES `taxon_concepts` WRITE;
/*!40000 ALTER TABLE `taxon_concepts` DISABLE KEYS */;
/*!40000 ALTER TABLE `taxon_concepts` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `title_items`
--

LOCK TABLES `title_items` WRITE;
/*!40000 ALTER TABLE `title_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `title_items` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `top_images`
--

LOCK TABLES `top_images` WRITE;
/*!40000 ALTER TABLE `top_images` DISABLE KEYS */;
/*!40000 ALTER TABLE `top_images` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `top_unpublished_images`
--

LOCK TABLES `top_unpublished_images` WRITE;
/*!40000 ALTER TABLE `top_unpublished_images` DISABLE KEYS */;
/*!40000 ALTER TABLE `top_unpublished_images` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `vetted`
--

LOCK TABLES `vetted` WRITE;
/*!40000 ALTER TABLE `vetted` DISABLE KEYS */;
INSERT INTO `vetted` VALUES (0,'Unknown','2009-01-15 21:06:58','2009-01-15 21:06:58'),(1,'Untrusted','2009-01-15 21:06:58','2009-01-15 21:06:58'),(2,'Trusted','2009-01-15 21:06:58','2009-01-15 21:06:58');
/*!40000 ALTER TABLE `vetted` ENABLE KEYS */;
UNLOCK TABLES;

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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `visibilities`
--

LOCK TABLES `visibilities` WRITE;
/*!40000 ALTER TABLE `visibilities` DISABLE KEYS */;
INSERT INTO `visibilities` VALUES (0,'Invisible','2009-01-15 21:06:57','2009-01-15 21:06:57'),(1,'Visible','2009-01-15 21:06:52','2009-01-15 21:06:52'),(2,'Preview','2009-01-15 21:06:52','2009-01-15 21:06:52'),(3,'Inappropriate','2009-01-15 21:06:52','2009-01-15 21:06:52');
/*!40000 ALTER TABLE `visibilities` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-01-15 21:10:32
