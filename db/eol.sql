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
-- Dumping data for table `comments`
--

LOCK TABLES `comments` WRITE;
/*!40000 ALTER TABLE `comments` DISABLE KEYS */;
/*!40000 ALTER TABLE `comments` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `contacts`
--

LOCK TABLES `contacts` WRITE;
/*!40000 ALTER TABLE `contacts` DISABLE KEYS */;
/*!40000 ALTER TABLE `contacts` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `content_page_archives`
--

LOCK TABLES `content_page_archives` WRITE;
/*!40000 ALTER TABLE `content_page_archives` DISABLE KEYS */;
/*!40000 ALTER TABLE `content_page_archives` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `content_pages`
--

LOCK TABLES `content_pages` WRITE;
/*!40000 ALTER TABLE `content_pages` DISABLE KEYS */;
INSERT INTO `content_pages` VALUES (1,'Screencasts','Screencasts','',2,1,'','<h1>Horizontal contextually-based concept</h1><p>Maxime fugiat veritatis id sunt est et. Sed fugiat eos aut omnis ea sit. Qui laboriosam repellat in veritatis qui dolores aut.</p><p>Voluptatem numquam deserunt libero aut omnis. Laudantium excepturi atque libero. Aspernatur sed accusantium molestiae rerum et. Odit sunt consequatur illo reiciendis omnis id.</p><p>Qui doloremque recusandae optio et vel saepe exercitationem ut. Aspernatur non culpa qui. Eius nisi facere qui. Quos suscipit dicta ipsum nulla voluptas nihil doloribus.</p>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(2,'FAQs','FAQs','',2,2,'','<h1>Organized well-modulated utilisation</h1><p>Adipisci molestias ea veniam quo. Beatae eum nulla qui exercitationem dolorem aut qui neque. Earum rerum voluptatum fugit libero consequuntur facilis dignissimos. Doloremque modi nisi rem ut.</p><p>Quia et necessitatibus reprehenderit et fugit ut. Autem qui placeat blanditiis magnam corporis earum laboriosam est. Omnis laudantium a ipsa accusamus iure quis autem maxime. Error doloremque omnis voluptatum ut delectus rerum. Quae soluta et maiores inventore cum.</p><p>Minus laudantium libero a blanditiis aspernatur. Illum sit aut tenetur incidunt eum. Quisquam et assumenda quod inventore ut consequatur.</p>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(3,'Press Releases','Press Releases','',3,1,'','<h1>Cross-group assymetric focus group</h1><p>Officiis at autem vel temporibus. Exercitationem quia autem et sed odio accusamus. Laboriosam maiores ea minima. Rerum porro consectetur quas officiis. Voluptatum quasi ipsum sit aut deleniti.</p><p>Autem tempore autem impedit fugiat. Consequuntur voluptatibus saepe cumque error aut sit tenetur. Culpa atque aliquid recusandae maiores in molestiae. Nesciunt omnis illo sed. Nihil sit eos odio dolor est tempore.</p><p>Vel autem fuga harum alias quis. Est velit dolore sed nesciunt quaerat quam. Dolor cupiditate incidunt vel libero ab ea eius.</p>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(4,'Publications','Publications','',3,2,'','<h1>Phased system-worthy secured line</h1><p>Dolor animi dolorem voluptatem occaecati accusamus non. Beatae et eaque accusantium iusto nihil nulla. Voluptatem quia recusandae sunt assumenda vero. Quia deleniti ratione optio. Ad voluptatem saepe beatae.</p><p>Harum id fugit debitis. Facere tempore provident qui expedita. Qui ullam et voluptatem error. Aut soluta beatae quia quae aut.</p><p>Minima voluptatum enim voluptas. Sit culpa officia cum. Animi et optio quia ipsum vel. Sunt vel reiciendis vel illum consequatur aliquam.</p>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(5,'Newsletter','Newsletter','',3,3,'','<h1>Open-source high-level moratorium</h1><p>Pariatur et animi dicta sit quod. At possimus doloremque nemo cupiditate consequuntur ipsum. Occaecati ea beatae perferendis.</p><p>Sunt omnis perferendis accusantium impedit excepturi. Quia impedit nostrum et sed id. Officia ipsa provident amet et eligendi. Qui vitae eum blanditiis sit dolorem. Eos hic sit libero cupiditate at.</p><p>Ad iusto aliquam repellendus dolor unde quo. Incidunt numquam voluptates consequuntur impedit doloremque omnis corrupti. Atque nobis tenetur rerum numquam laudantium molestiae iste. Reprehenderit eum impedit tempore repellat. Iusto nostrum quia nihil sit provident.</p>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(6,'Who We Are','Who We Are','',1,1,'','<h1>Customer-focused uniform artificial intelligence</h1><p>Ut nulla aperiam adipisci quis. Ut ut incidunt ullam molestiae recusandae sed. Est tempore amet vitae. Occaecati debitis laboriosam eum explicabo deserunt optio facere.</p><p>Reiciendis necessitatibus fuga rem enim vel illo distinctio voluptates. Quo totam at dolorem soluta quos animi maxime excepturi. Sed facilis recusandae velit autem accusamus.</p><p>Neque eveniet deleniti et voluptatem quibusdam rerum voluptatibus hic. Optio eius ex neque libero repellat eaque accusantium. Eum commodi doloremque dolores aperiam delectus facilis reprehenderit mollitia. Voluptatem nobis eaque veritatis. Molestias nesciunt ex natus libero.</p>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(7,'Donors','Donors','',1,2,'','<h1>Multi-layered scalable system engine</h1><p>Ut cupiditate error delectus recusandae aliquam ea sunt consequatur. Et laudantium mollitia sint ut atque et quas. Porro sed voluptates explicabo debitis occaecati eum.</p><p>Quis facere animi blanditiis aut. In accusamus itaque molestias beatae distinctio neque. Nihil facilis porro qui et. Eaque animi nemo minima.</p><p>Deserunt nemo dolorem vel et voluptatem sed. Sunt excepturi et maiores laborum. Vel sit nihil aut et ut corporis nulla ullam. Ipsum molestiae sapiente iste aspernatur et rerum beatae illo. Quaerat sapiente officia repellat vero occaecati voluptates dolores.</p>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(8,'Institutional Partners','Institutional Partners','',1,3,'','<h1>Synergized bandwidth-monitored conglomeration</h1><p>Adipisci quam dolore molestiae quo. Amet rem cumque voluptatem maiores. Animi quo libero quis eius similique amet repellat. Alias et fugiat qui voluptas porro.</p><p>Fugiat natus aut aliquid. Excepturi accusantium ea neque. Velit repellendus vitae odio ad sit. Dolorem possimus in tempore consectetur molestias eius est. Omnis officiis quia esse non et.</p><p>Fugiat praesentium earum aut adipisci vero. Amet qui modi qui in. Commodi eos quis occaecati.</p>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(9,'Milestones','Milestones','',1,4,'','<h1>Decentralized analyzing system engine</h1><p>Est nulla velit excepturi esse quod soluta. Facere ipsam omnis veniam omnis aut voluptatem enim. Numquam nulla qui inventore architecto autem qui omnis sed. At et ipsa suscipit magni beatae quia ipsam aut. Et velit modi deleniti velit eaque explicabo neque nostrum.</p><p>Tempore modi ipsum laborum vitae beatae. Ut ea consequatur earum doloribus. Sequi debitis magnam ut ea optio id esse itaque. Veritatis ducimus dolor qui quam iure totam. Autem accusamus est velit repudiandae.</p><p>Debitis voluptatem delectus deserunt harum tenetur optio libero. Natus aperiam excepturi voluptatibus atque. At expedita neque quaerat.</p>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(10,'Upcoming Events','Upcoming Events','',1,5,'','<h1>Intuitive intermediate task-force</h1><p>Ut fugit voluptates quam quia necessitatibus. Non necessitatibus in sint. Perferendis et beatae sequi non aliquid nulla corporis. Quasi quis praesentium illo non sit. Autem reiciendis necessitatibus possimus consequuntur rerum voluptatibus et eligendi.</p><p>Eum incidunt fuga laborum sit. Ad et saepe culpa dolore aut dolores. Incidunt autem aut enim facere.</p><p>Voluptatum accusantium exercitationem esse ducimus natus. Et rerum corrupti alias repudiandae soluta molestiae. Iusto possimus aut laboriosam est quia. Eos autem molestiae necessitatibus et. Optio delectus reprehenderit dolores dolor aperiam.</p>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(11,'Employment','Employment','',1,6,'','<h1>Assimilated background artificial intelligence</h1><p>Et facilis pariatur debitis occaecati tempora amet. Temporibus velit consequatur fugit ab sit. Voluptatem ipsa autem in eum voluptatem temporibus voluptate.</p><p>Quam omnis accusantium consequatur dolorum velit at. Quo temporibus est eos corporis et. Vel omnis eaque quibusdam. Laborum ea dignissimos blanditiis quia aut.</p><p>Modi vitae ut inventore sunt. Animi qui rerum sapiente id laudantium quod explicabo amet. Optio possimus laboriosam et beatae. Expedita quis accusantium quos deleniti explicabo.</p>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(12,'Industry Partners','Industry Partners','',1,7,'','<h1>Public-key 4th generation initiative</h1><p>Alias pariatur corrupti perferendis commodi in harum. Qui sit et cupiditate eaque. Inventore asperiores est quae vel numquam nostrum. Natus nisi non et. Tenetur ut repudiandae ea ab nihil debitis.</p><p>Minus eligendi facilis dolore id eum. Distinctio eum recusandae sed nam deleniti velit. Qui omnis ad qui modi possimus aliquam eveniet voluptatem. Vel rerum quia dolor illum animi ipsam ut nulla. Cum voluptatibus ullam voluptatem architecto.</p><p>Et dicta ut possimus inventore tempora voluptates qui vero. Consequatur deleniti ut tenetur commodi recusandae error laboriosam beatae. Ad est sapiente quo expedita autem.</p>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(13,'Terms Of Use','Terms Of Use','',4,1,'','<h1>Cross-platform background projection</h1><p>Numquam quaerat rerum aperiam reprehenderit quis accusantium corporis dolorum. Corporis est voluptatum voluptates deleniti. Iure possimus omnis consequatur esse. Doloremque ipsam et voluptatibus aut delectus.</p><p>Quidem optio ipsam occaecati officiis explicabo. Sint neque dolorum hic sapiente. Voluptatem voluptatem labore laudantium nobis aut.</p><p>Illum natus dolorem et fugiat aut ratione magnam. Est in sint rerum quas dicta eum consequatur qui. Alias sit consequatur nisi doloribus voluptatibus et. Aliquid qui nobis facere labore quia cum odit officia. Quia quia fugit quos odit sunt quod.</p>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(14,'Home','Home','',5,1,'<h1>Welcome</h1>The Encyclopedia of Life (EOL) is an ambitious project to organize and make available via the Internet virtually all information about life present on Earth. At its heart lies a series of Web sites—one for each of the approximately 1.8 million known species.  Each site is constantly evolving and features dynamically synthesized content ranging from historical literature and biological descriptions to stunning images, videos and distribution maps. Join us as we explore the richness of Earth’s biodiversity!<br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br /><br />','<h1>What\'s New?</h1><ul class=\"helplist\"><li>We recently welcomed new <a href=\"/content/page/data_partners\">content partners</a> and added rich information on many new species. The EOL staff enjoys watching the updated home page sample the new ants, birds, mammals, fungi, plants, and spiders, and we hope you do too!</li><li>The Encyclopedia of Life and Microsoft Photosynth bring a new experience to users! <a href=\"/content/page/photosynth\">Explore the innovative software</a> that provides a fresh way to visualize species.</li></ul><br /><br /><h1>Help Us</h1><p>EOL is an unprecedented global effort and we want you to be a part of it. Natural history museums, botanical gardens, other research institutions, and dedicated individuals are working to create the most complete biodiversity database on the Web, but without your help it cannot be done. Here are some ways in which you can become involved:</p><ul class=\"helplist\"><li><strong>Provide content.</strong> (coming later in 2008)</li> <li><strong>Become a curator.</strong> (coming later in 2008, but you can <a href=\"/contact_us\">contact us</a> now to express interest)</li><li><strong>Become a donor to the EOL.</strong> Make <a href=\"/donate\">a financial donation</a>.</li></ul>',1,'2009-01-15 21:06:47','2009-01-15 21:06:47','en','',0,2),(15,'Contact Us','Contact Us','',7,1,'','',1,'2009-01-15 21:06:58','2009-01-15 21:06:58','en','/contact_us',0,2),(16,'Forum','Forum','',7,2,'','',1,'2009-01-15 21:06:58','2009-01-15 21:06:58','en','http://forum.eol.org',1,2),(17,'Blog','Blog','',7,3,'','',1,'2009-01-15 21:06:58','2009-01-15 21:06:58','en','http://blog.eol.org',1,2),(18,'Media Contact','Media Contact','',3,1,'','',1,'2009-01-15 21:06:58','2009-01-15 21:06:58','en','/media_contact',0,2),(19,'Content Partners','Content Partners','',1,20,'','',1,'2009-01-15 21:06:58','2009-01-15 21:06:58','en','/content/partners',0,2),(20,'Exemplars','Exemplars','',1,25,'','',1,'2009-01-15 21:06:58','2009-01-15 21:06:58','en','/content/exemplars',0,2),(21,'Comments and Corrections','Comments and Corrections','',4,2,'','',1,'2009-01-15 21:06:59','2009-01-15 21:06:59','en','/contact_us',0,2),(22,'Encyclopedia of Life','Encyclopedia of Life','',4,3,'','',1,'2009-01-15 21:06:59','2009-01-15 21:06:59','en','/',0,2);
/*!40000 ALTER TABLE `content_pages` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `content_sections`
--

LOCK TABLES `content_sections` WRITE;
/*!40000 ALTER TABLE `content_sections` DISABLE KEYS */;
INSERT INTO `content_sections` VALUES (1,'About EOL','','2009-01-15 21:06:46','2009-01-15 21:06:46'),(2,'Using the Site','','2009-01-15 21:06:46','2009-01-15 21:06:46'),(3,'Press Room','','2009-01-15 21:06:46','2009-01-15 21:06:46'),(4,'Footer','','2009-01-15 21:06:46','2009-01-15 21:06:46'),(5,'Home Page','','2009-01-15 21:06:46','2009-01-15 21:06:46'),(6,'Other','','2009-01-15 21:06:46','2009-01-15 21:06:46'),(7,'Feedback','','2009-01-15 21:06:58','2009-01-15 21:06:58');
/*!40000 ALTER TABLE `content_sections` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `data_object_data_object_tags`
--

LOCK TABLES `data_object_data_object_tags` WRITE;
/*!40000 ALTER TABLE `data_object_data_object_tags` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_object_data_object_tags` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `data_object_tags`
--

LOCK TABLES `data_object_tags` WRITE;
/*!40000 ALTER TABLE `data_object_tags` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_object_tags` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `error_logs`
--

LOCK TABLES `error_logs` WRITE;
/*!40000 ALTER TABLE `error_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `error_logs` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `news_items`
--

LOCK TABLES `news_items` WRITE;
/*!40000 ALTER TABLE `news_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `news_items` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `open_id_authentication_associations`
--

LOCK TABLES `open_id_authentication_associations` WRITE;
/*!40000 ALTER TABLE `open_id_authentication_associations` DISABLE KEYS */;
/*!40000 ALTER TABLE `open_id_authentication_associations` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `open_id_authentication_nonces`
--

LOCK TABLES `open_id_authentication_nonces` WRITE;
/*!40000 ALTER TABLE `open_id_authentication_nonces` DISABLE KEYS */;
/*!40000 ALTER TABLE `open_id_authentication_nonces` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'Administrator','2009-01-15 21:06:50','2009-01-15 21:06:50'),(2,'Curator','2009-01-15 21:06:50','2009-01-15 21:06:50'),(3,'Moderator','2009-01-15 21:06:50','2009-01-15 21:06:50'),(4,'Administrator - Contact Us Submissions','2009-01-15 21:06:50','2009-01-15 21:06:50'),(5,'Administrator - Site CMS','2009-01-15 21:06:50','2009-01-15 21:06:50'),(6,'Administrator - Web Users','2009-01-15 21:06:50','2009-01-15 21:06:50'),(7,'Administrator - Content Partners','2009-01-15 21:06:50','2009-01-15 21:06:50'),(8,'Administrator - Error Logs','2009-01-15 21:06:50','2009-01-15 21:06:50'),(9,'Administrator - Usage Reports','2009-01-15 21:06:50','2009-01-15 21:06:50'),(10,'Administrator - News Items','2009-01-15 16:06:53',NULL);
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `roles_users`
--

LOCK TABLES `roles_users` WRITE;
/*!40000 ALTER TABLE `roles_users` DISABLE KEYS */;
INSERT INTO `roles_users` VALUES (2,1),(2,4),(2,5),(2,6),(2,7),(2,8),(2,9);
/*!40000 ALTER TABLE `roles_users` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `search_suggestions`
--

LOCK TABLES `search_suggestions` WRITE;
/*!40000 ALTER TABLE `search_suggestions` DISABLE KEYS */;
/*!40000 ALTER TABLE `search_suggestions` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `sessions`
--

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `survey_responses`
--

LOCK TABLES `survey_responses` WRITE;
/*!40000 ALTER TABLE `survey_responses` DISABLE KEYS */;
/*!40000 ALTER TABLE `survey_responses` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `taxon_stats`
--

LOCK TABLES `taxon_stats` WRITE;
/*!40000 ALTER TABLE `taxon_stats` DISABLE KEYS */;
/*!40000 ALTER TABLE `taxon_stats` ENABLE KEYS */;
UNLOCK TABLES;

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
-- Dumping data for table `unique_visitors`
--

LOCK TABLES `unique_visitors` WRITE;
/*!40000 ALTER TABLE `unique_visitors` DISABLE KEYS */;
INSERT INTO `unique_visitors` VALUES (1,0,'2009-01-15 21:06:46','2009-01-15 21:06:46');
/*!40000 ALTER TABLE `unique_visitors` ENABLE KEYS */;
UNLOCK TABLES;

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
  `active` tinyint(1) default NULL,
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

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (2,NULL,NULL,NULL,NULL,'no_reply@example.com','administrator','master',NULL,'admin','21232f297a57a5a743894a0e4a801fc3',NULL,NULL,NULL,1,NULL,NULL,NULL,NULL,NULL,0,NULL,NULL,'','',0);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2009-01-15 21:10:54
