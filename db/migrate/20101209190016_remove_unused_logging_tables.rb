class RemoveUnusedLoggingTables < EOL::LoggingMigration
  def self.up
    # drop_table :agent_log_dailies
    # drop_table :country_log_dailies
    # drop_table :curator_activity_log_dailies
    # drop_table :curator_comment_logs
    # drop_table :data_object_logs
    # drop_table :data_object_log_dailies
    # drop_table :links
    # drop_table :state_log_dailies
    # drop_table :user_log_dailies
    # 
    # remove_column :activity_logs, :link_id
  end
  
  def self.down
    execute "ALTER TABLE activity_logs ADD `link_id` int(11) default NULL after `activity_id`"
    
    execute "
        CREATE TABLE `agent_log_dailies` (
          `id` int(11) NOT NULL auto_increment,
          `agent_id` int(11) NOT NULL,
          `data_type_id` int(11) NOT NULL,
          `total` int(11) NOT NULL,
          `day` date NOT NULL,
          PRIMARY KEY  (`id`),
          KEY `index_agent_log_dailies_on_agent_id` (`agent_id`),
          KEY `index_agent_log_dailies_on_day` (`day`)
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8"
    
    execute "
        CREATE TABLE `country_log_dailies` (
          `id` int(11) NOT NULL auto_increment,
          `country_code` varchar(255) default NULL,
          `data_type_id` int(11) NOT NULL,
          `total` int(11) NOT NULL,
          `day` date NOT NULL,
          `agent_id` int(11) NOT NULL,
          PRIMARY KEY  (`id`),
          KEY `index_country_log_dailies_on_agent_id` (`agent_id`),
          KEY `index_country_log_dailies_on_day` (`day`),
          KEY `index_country_log_dailies_on_country_code` (`country_code`)
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8"
    
    execute "
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
          PRIMARY KEY  (`id`),
          KEY `index_curator_activity_log_dailies_on_user_id` (`user_id`)
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8"
    
    execute "
        CREATE TABLE `curator_comment_logs` (
          `id` int(11) NOT NULL auto_increment,
          `user_id` int(11) NOT NULL,
          `comment_id` int(11) NOT NULL,
          `created_at` datetime NOT NULL,
          `updated_at` datetime NOT NULL,
          `curator_activity_id` int(11) NOT NULL,
          PRIMARY KEY  (`id`)
        ) ENGINE=MyISAM AUTO_INCREMENT=148 DEFAULT CHARSET=utf8"
    
    execute "
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
          PRIMARY KEY  (`id`),
          KEY `index_data_object_logs_on_created_at` (`created_at`)
        ) ENGINE=MyISAM AUTO_INCREMENT=11855406 DEFAULT CHARSET=utf8"
    
    execute "
        CREATE TABLE `data_object_log_dailies` (
          `id` int(11) NOT NULL auto_increment,
          `data_object_id` int(11) NOT NULL,
          `data_type_id` int(11) NOT NULL,
          `total` int(11) NOT NULL,
          `day` date NOT NULL,
          `agent_id` int(11) NOT NULL,
          PRIMARY KEY  (`id`),
          KEY `index_data_object_log_dailies_on_agent_id` (`agent_id`),
          KEY `index_data_object_log_dailies_on_day` (`day`),
          KEY `index_data_object_log_dailies_on_data_object_id` (`data_object_id`)
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8"
    
    execute "
        CREATE TABLE `links` (
          `id` int(11) NOT NULL auto_increment,
          `url` varchar(255) default NULL,
          PRIMARY KEY  (`id`)
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8"
    
    execute "
        CREATE TABLE `state_log_dailies` (
          `id` int(11) NOT NULL auto_increment,
          `state_code` varchar(255) default NULL,
          `data_type_id` int(11) NOT NULL,
          `total` int(11) NOT NULL,
          `day` date NOT NULL,
          `agent_id` int(11) NOT NULL,
          PRIMARY KEY  (`id`),
          KEY `index_state_log_dailies_on_agent_id` (`agent_id`),
          KEY `index_state_log_dailies_on_day` (`day`),
          KEY `index_state_log_dailies_on_state_code` (`state_code`)
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8"
    
    execute "
        CREATE TABLE `user_log_dailies` (
          `id` int(11) NOT NULL auto_increment,
          `user_id` int(11) NOT NULL,
          `data_type_id` int(11) NOT NULL,
          `total` int(11) NOT NULL,
          `day` date NOT NULL,
          `agent_id` int(11) NOT NULL,
          PRIMARY KEY  (`id`),
          KEY `index_user_log_dailies_on_agent_id` (`agent_id`),
          KEY `index_user_log_dailies_on_day` (`day`),
          KEY `index_user_log_dailies_on_user_id` (`user_id`)
        ) ENGINE=MyISAM DEFAULT CHARSET=utf8"
  end
end
