class CreateGoogleStatTables < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end  
  def self.up
  
    execute "
        CREATE TABLE `google_analytics_page_stat` (
        `taxon_concept_id` int(10) unsigned NOT NULL default '0',
        `year` smallint(4) NOT NULL,
        `month` tinyint(2) NOT NULL,
        `page_views` int(10) unsigned NOT NULL,
        `unique_page_views` int(10) unsigned NOT NULL,
        `time_on_page` time NOT NULL,
        KEY `taxon_concept_id` (`taxon_concept_id`),
        KEY `year` (`year`),
        KEY `month` (`month`),
        KEY `page_views` (`page_views`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT=''"
        
    execute "            
        CREATE TABLE `google_analytics_partner_summaries` (
        `year` smallint(4) NOT NULL default '0',
        `month` tinyint(2) NOT NULL default '0',
        `agent_id` int(11) NOT NULL default '0',
        `taxa_pages` int(11) default NULL,
        `taxa_pages_viewed` int(11) default NULL,
        `unique_page_views` int(11) default NULL,
        `page_views` int(11) default NULL,
        `time_on_page` float(11,2) default NULL,
        PRIMARY KEY  (`agent_id`,`year`,`month`),
        KEY `year` (`year`),
        KEY `month` (`month`),
        KEY `agent_id` (`agent_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT=''"
        
    execute "        
        CREATE TABLE `google_analytics_partner_taxa` (
        `taxon_concept_id` int(10) unsigned NOT NULL,
        `agent_id` int(10) unsigned NOT NULL,
        `year` smallint(4) NOT NULL,
        `month` tinyint(2) NOT NULL,
        KEY `taxon_concept_id` (`taxon_concept_id`),
        KEY `agent_id` (`agent_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT=''"

    execute "        
        CREATE TABLE `google_analytics_summaries` (
        `year` smallint(4) NOT NULL,
        `month` tinyint(2) NOT NULL,
        `visits` int(11) default NULL,
        `visitors` int(11) default NULL,
        `pageviews` int(11) default NULL,
        `unique_pageviews` int(11) default NULL,
        `ave_pages_per_visit` float default NULL,
        `ave_time_on_site` time default NULL,
        `ave_time_on_page` time default NULL,
        `per_new_visits` float default NULL,
        `bounce_rate` float default NULL,
        `per_exit` float default NULL,
        `taxa_pages` int(11) default NULL,
        `taxa_pages_viewed` int(11) default NULL,
        PRIMARY KEY  (`year`,`month`),
        KEY `year` (`year`),
        KEY `month` (`month`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT=''"    
  end

  def self.down
    drop_table :google_analytics_page_stat
    drop_table :google_analytics_partner_summaries
    drop_table :google_analytics_partner_taxa
    drop_table :google_analytics_summaries
  end  
end
