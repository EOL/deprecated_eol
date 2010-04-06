class ChangeAgentNameToText < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    remove_index :agents, :name => 'full_name'
    execute('alter table agents modify `full_name` text NOT NULL')
    execute('alter table agents modify `homepage` text NOT NULL')
    execute('create index full_name on agents (full_name(200))')
    
  end
  
  def self.down
    remove_index :agents, :name => 'full_name'
    execute('alter table agents modify `full_name` varchar(400) NOT NULL')
    execute('alter table agents modify `homepage` varchar(255) NOT NULL')
    execute('create index full_name on agents (full_name)')
  end
end
