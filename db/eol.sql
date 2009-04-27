-- MySQL dump 10.11
--
-- Host: localhost    Database: eol_development_rails
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
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `comments` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `parent_id` int(11) NOT NULL,
  `parent_type` varchar(255) NOT NULL,
  `body` text NOT NULL,
  `visible_at` datetime default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_comments_on_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `contact_subjects`
--

DROP TABLE IF EXISTS `contact_subjects`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `contact_subjects` (
  `id` int(11) NOT NULL auto_increment,
  `title` varchar(255) default NULL,
  `recipients` varchar(255) default NULL,
  `active` tinyint(1) NOT NULL default '1',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `contacts`
--

DROP TABLE IF EXISTS `contacts`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `contacts` (
  `id` int(11) NOT NULL auto_increment,
  `contact_subject_id` int(11) default NULL,
  `name` varchar(255) default NULL,
  `email` varchar(255) default NULL,
  `comments` text,
  `ip_address` varchar(255) default NULL,
  `referred_page` varchar(255) default NULL,
  `user_id` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `taxon_group` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `content_page_archives`
--

DROP TABLE IF EXISTS `content_page_archives`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `content_page_archives` (
  `id` int(11) NOT NULL auto_increment,
  `content_page_id` int(11) default NULL,
  `page_name` varchar(255) NOT NULL default '',
  `title` varchar(255) default '',
  `language_key` varchar(255) NOT NULL default '',
  `content_section_id` int(11) default NULL,
  `sort_order` int(11) NOT NULL default '1',
  `left_content` text NOT NULL,
  `main_content` text NOT NULL,
  `original_creation_date` datetime default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `language_abbr` varchar(255) NOT NULL default 'en',
  `url` varchar(255) default '',
  `open_in_new_window` tinyint(1) default '0',
  `last_update_user_id` int(11) NOT NULL default '2',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `content_pages`
--

DROP TABLE IF EXISTS `content_pages`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `content_pages` (
  `id` int(11) NOT NULL auto_increment,
  `page_name` varchar(255) NOT NULL default '',
  `title` varchar(255) NOT NULL default '',
  `language_key` varchar(255) NOT NULL default '',
  `content_section_id` int(11) default NULL,
  `sort_order` int(11) NOT NULL default '1',
  `left_content` text NOT NULL,
  `main_content` text NOT NULL,
  `active` tinyint(1) NOT NULL default '1',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `language_abbr` varchar(255) NOT NULL default 'en',
  `url` varchar(255) default '',
  `open_in_new_window` tinyint(1) default '0',
  `last_update_user_id` int(11) NOT NULL default '2',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `content_sections`
--

DROP TABLE IF EXISTS `content_sections`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `content_sections` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  `language_key` varchar(255) NOT NULL default '',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `data_object_data_object_tags`
--

DROP TABLE IF EXISTS `data_object_data_object_tags`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `data_object_data_object_tags` (
  `id` int(11) NOT NULL auto_increment,
  `data_object_id` int(11) NOT NULL,
  `data_object_tag_id` int(11) NOT NULL,
  `user_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `data_object_tags`
--

DROP TABLE IF EXISTS `data_object_tags`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `data_object_tags` (
  `id` int(11) NOT NULL auto_increment,
  `key` varchar(255) NOT NULL,
  `value` varchar(255) NOT NULL,
  `is_public` tinyint(1) default NULL,
  `total_usage_count` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `error_logs`
--

DROP TABLE IF EXISTS `error_logs`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `error_logs` (
  `id` int(11) NOT NULL auto_increment,
  `exception_name` varchar(250) default NULL,
  `backtrace` text,
  `url` varchar(250) default NULL,
  `user_id` int(11) default NULL,
  `user_agent` varchar(100) default NULL,
  `ip_address` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `news_items`
--

DROP TABLE IF EXISTS `news_items`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `news_items` (
  `id` int(11) NOT NULL auto_increment,
  `body` varchar(1500) NOT NULL,
  `title` varchar(255) default '',
  `display_date` datetime default NULL,
  `activated_on` datetime default NULL,
  `user_id` int(11) default NULL,
  `active` tinyint(1) default '1',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `open_id_authentication_associations`
--

DROP TABLE IF EXISTS `open_id_authentication_associations`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `open_id_authentication_associations` (
  `id` int(11) NOT NULL auto_increment,
  `issued` int(11) default NULL,
  `lifetime` int(11) default NULL,
  `handle` varchar(255) default NULL,
  `assoc_type` varchar(255) default NULL,
  `server_url` blob,
  `secret` blob,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `open_id_authentication_nonces`
--

DROP TABLE IF EXISTS `open_id_authentication_nonces`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `open_id_authentication_nonces` (
  `id` int(11) NOT NULL auto_increment,
  `timestamp` int(11) NOT NULL,
  `server_url` varchar(255) default NULL,
  `salt` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `roles` (
  `id` int(11) NOT NULL auto_increment,
  `title` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `roles_users`
--

DROP TABLE IF EXISTS `roles_users`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `roles_users` (
  `user_id` int(11) NOT NULL default '0',
  `role_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`role_id`,`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `search_suggestions`
--

DROP TABLE IF EXISTS `search_suggestions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `search_suggestions` (
  `id` int(11) NOT NULL auto_increment,
  `term` varchar(255) NOT NULL default '',
  `scientific_name` varchar(255) NOT NULL default '',
  `common_name` varchar(255) NOT NULL default '',
  `language_label` varchar(255) NOT NULL default 'en',
  `image_url` varchar(255) NOT NULL default '',
  `taxon_id` varchar(255) NOT NULL default '',
  `notes` text,
  `content_notes` varchar(255) NOT NULL default '',
  `sort_order` int(11) NOT NULL default '1',
  `active` tinyint(1) NOT NULL default '1',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `sessions` (
  `id` int(11) NOT NULL auto_increment,
  `session_id` varchar(255) NOT NULL,
  `data` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `survey_responses`
--

DROP TABLE IF EXISTS `survey_responses`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `survey_responses` (
  `id` int(11) NOT NULL auto_increment,
  `taxon_id` varchar(255) default NULL,
  `user_response` varchar(255) default NULL,
  `user_id` int(11) default NULL,
  `user_agent` varchar(100) default NULL,
  `ip_address` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `taxon_stats`
--

DROP TABLE IF EXISTS `taxon_stats`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `taxon_stats` (
  `id` int(11) NOT NULL auto_increment,
  `taxa` varchar(255) default NULL,
  `text` varchar(255) default NULL,
  `image` varchar(255) default NULL,
  `text_and_images` varchar(255) default NULL,
  `bhl_no_text` varchar(255) default NULL,
  `link_no_text` varchar(255) default NULL,
  `image_no_text` varchar(255) default NULL,
  `text_no_image` varchar(255) default NULL,
  `text_or_image` varchar(255) default NULL,
  `text_or_child_image` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `unique_visitors`
--

DROP TABLE IF EXISTS `unique_visitors`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `unique_visitors` (
  `id` int(11) NOT NULL auto_increment,
  `count` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `default_taxonomic_browser` varchar(24) default NULL,
  `expertise` varchar(24) default NULL,
  `remote_ip` varchar(24) default NULL,
  `content_level` int(11) default NULL,
  `email` varchar(255) default NULL,
  `given_name` varchar(255) default NULL,
  `family_name` varchar(255) default NULL,
  `identity_url` varchar(255) default NULL,
  `username` varchar(32) default NULL,
  `hashed_password` varchar(32) default NULL,
  `flash_enabled` tinyint(1) default NULL,
  `vetted` tinyint(1) default NULL,
  `mailing_list` tinyint(1) default NULL,  
  `active` tinyint(1) default NULL COMMENT='when you create an account, you are sent an email to activate it',
  `language_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `notes` text,
  `curator_hierarchy_entry_id` int(11) default NULL,
  `curator_approved` tinyint(1) NOT NULL default '0',
  `curator_verdict_by_id` int(11) default NULL,
  `curator_verdict_at` datetime default NULL,
  `credentials` text NOT NULL,
  `validation_code` varchar(255) default '',
  `failed_login_attempts` int(11) default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-01-15 21:10:54
