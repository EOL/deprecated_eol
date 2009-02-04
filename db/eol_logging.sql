-- MySQL dump 10.11
--
-- Host: localhost    Database: eol_logging_development_rails
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
-- Table structure for table `agent_log_dailies`
--

DROP TABLE IF EXISTS `agent_log_dailies`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `agent_log_dailies` (
  `id` int(11) NOT NULL auto_increment,
  `agent_id` int(11) NOT NULL,
  `data_type_id` int(11) NOT NULL,
  `total` int(11) NOT NULL,
  `day` date NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `country_log_dailies`
--

DROP TABLE IF EXISTS `country_log_dailies`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `country_log_dailies` (
  `id` int(11) NOT NULL auto_increment,
  `country_code` varchar(255) default NULL,
  `data_type_id` int(11) NOT NULL,
  `total` int(11) NOT NULL,
  `day` date NOT NULL,
  `agent_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `curator_activities`
--

DROP TABLE IF EXISTS `curator_activities`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `curator_activities` (
  `id` int(11) NOT NULL auto_increment,
  `code` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `curator_activities`
--

LOCK TABLES `curator_activities` WRITE;
/*!40000 ALTER TABLE `curator_activities` DISABLE KEYS */;
INSERT INTO `curator_activities` VALUES (1,'delete','0000-00-00 00:00:00','0000-00-00 00:00:00'),(2,'update','0000-00-00 00:00:00','0000-00-00 00:00:00');
/*!40000 ALTER TABLE `curator_activities` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `curator_activity_log_dailies`
--

DROP TABLE IF EXISTS `curator_activity_log_dailies`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `curator_activity_log_dailies` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL,
  `comments_updated` int(11) NOT NULL default '0',
  `comments_deleted` int(11) NOT NULL default '0',
  `data_objects_updated` int(11) NOT NULL default '0',
  `data_objects_deleted` int(11) NOT NULL default '0',
  `year` int(11) NOT NULL,
  `date` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `curator_comment_logs`
--

DROP TABLE IF EXISTS `curator_comment_logs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `curator_comment_logs` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL,
  `comment_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `curator_activity_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `curator_data_object_logs`
--

DROP TABLE IF EXISTS `curator_data_object_logs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `curator_data_object_logs` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL,
  `data_object_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `curator_activity_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `data_object_log_dailies`
--

DROP TABLE IF EXISTS `data_object_log_dailies`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `data_object_log_dailies` (
  `id` int(11) NOT NULL auto_increment,
  `data_object_id` int(11) NOT NULL,
  `data_type_id` int(11) NOT NULL,
  `total` int(11) NOT NULL,
  `day` date NOT NULL,
  `agent_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `data_object_logs`
--

DROP TABLE IF EXISTS `data_object_logs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `data_object_logs` (
  `id` int(11) NOT NULL auto_increment,
  `data_object_id` int(11) NOT NULL,
  `data_type_id` int(11) NOT NULL,
  `ip_address_raw` int(11) NOT NULL,
  `ip_address_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `agent_id` int(11) default NULL,
  `user_agent` varchar(160) NOT NULL,
  `path` varchar(128) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `taxon_concept_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `external_link_logs`
--

DROP TABLE IF EXISTS `external_link_logs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `external_link_logs` (
  `id` int(11) NOT NULL auto_increment,
  `external_url` varchar(255) NOT NULL,
  `ip_address_raw` int(11) NOT NULL,
  `ip_address_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `user_agent` varchar(160) NOT NULL,
  `path` varchar(128) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `ip_addresses`
--

DROP TABLE IF EXISTS `ip_addresses`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `ip_addresses` (
  `id` int(11) NOT NULL auto_increment,
  `number` int(11) NOT NULL,
  `success` tinyint(1) NOT NULL,
  `country_code` varchar(255) default NULL,
  `city` varchar(255) default NULL,
  `state` varchar(255) default NULL,
  `latitude` float default NULL,
  `longitude` float default NULL,
  `provider` varchar(255) NOT NULL,
  `street_address` varchar(255) default NULL,
  `postal_code` varchar(255) default NULL,
  `precision` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `search_logs`
--

DROP TABLE IF EXISTS `search_logs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `search_logs` (
  `id` int(11) NOT NULL auto_increment,
  `search_term` varchar(255) default NULL,
  `total_number_of_results` int(11) default NULL,
  `number_of_common_name_results` int(11) default NULL,
  `number_of_scientific_name_results` int(11) default NULL,
  `number_of_suggested_results` int(11) default NULL,
  `number_of_stub_page_results` int(11) default NULL,
  `ip_address_raw` int(11) NOT NULL,
  `user_id` int(11) default NULL,
  `taxon_concept_id` int(11) default NULL,
  `parent_search_log_id` int(11) default NULL,
  `clicked_result_at` datetime default NULL,
  `user_agent` varchar(160) NOT NULL,
  `path` varchar(128) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `number_of_tag_results` int(11) default NULL,
  `search_type` varchar(255) default 'text',
  PRIMARY KEY  (`id`),
  KEY `index_search_logs_on_search_term` (`search_term`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `state_log_dailies`
--

DROP TABLE IF EXISTS `state_log_dailies`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `state_log_dailies` (
  `id` int(11) NOT NULL auto_increment,
  `state_code` varchar(255) default NULL,
  `data_type_id` int(11) NOT NULL,
  `total` int(11) NOT NULL,
  `day` date NOT NULL,
  `agent_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `user_log_dailies`
--

DROP TABLE IF EXISTS `user_log_dailies`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `user_log_dailies` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL,
  `data_type_id` int(11) NOT NULL,
  `total` int(11) NOT NULL,
  `day` date NOT NULL,
  `agent_id` int(11) NOT NULL,
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

-- Dump completed on 2009-01-15 21:10:43
