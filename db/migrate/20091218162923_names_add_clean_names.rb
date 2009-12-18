class NamesAddCleanNames < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute "alter table names add column clean_name varchar(300) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL COMMENT 'there is a one to one reltaionship between a name string and a clean name. The clean name takes the string and lowercases it (uncluding diacriticals), removes leading/trailing whitespace, removes some punctuation (periods and more), and pads remaining pun' after `string`"
    execute "update names n join clean_names cn on cn.name_id = n.id set n.clean_name = cn.clean_name"
    add_index :names, :clean_name, :name => "clean_name"
    execute "drop table clean_names"     
  end

  def self.down
    execute "CREATE TABLE `clean_names` (
      `name_id` int(10) unsigned NOT NULL,
      `clean_name` varchar(300) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL COMMENT 'there is a one to one reltaionship between a name string and a clean name. The clean name takes the string and lowercases it (uncluding diacriticals), removes leading/trailing whitespace, removes some punctuation (periods and more), and pads remaining pun',
      PRIMARY KEY (`name_id`),
      KEY `clean_name` (`clean_name`(255))
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Every name string as one clean name - a different simplified'"
    execute "insert into clean_names (select id, clean_name from names)"
    remove_column :names, :clean_name
  end
end
