class CreateWikipediaQueue < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute('CREATE TABLE `wikipedia_queue` (
      `id` int(11) NOT NULL auto_increment,
      `revision_id` int(11) NOT NULL,
      PRIMARY KEY  (`id`)
    ) ENGINE=InnoDB')
  end
  
  def self.down
    drop_table :wikipedia_queue
  end
end
