class ChangeDataObjectDescription < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute('alter table data_objects modify `description` mediumtext NOT NULL')
    execute('alter table data_objects modify `description_linked` mediumtext')
  end
  
  def self.down
    execute('alter table data_objects modify `description` text NOT NULL')
    execute('alter table data_objects modify `description_linked` text')
  end
end
