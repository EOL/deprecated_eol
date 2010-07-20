class CreateApiLogsTable < ActiveRecord::Migration
  def self.database_model
    return "LoggingModel"
  end

  def self.up
    execute("CREATE TABLE `api_logs` (
      `id` int(11) NOT NULL auto_increment,
      `request_ip` varchar(100) default NULL,
      `request_uri` varchar(200) default NULL,
      `method` varchar(100) default NULL,
      `version` varchar(10) default NULL,
      `request_id` varchar(50) default NULL,
      `format` varchar(10) default NULL,
      `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
      `updated_at` timestamp NOT NULL default '0000-00-00 00:00:00',
      PRIMARY KEY  (`id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8")
  end
  
  def self.down
    drop_table :api_logs
  end
end
