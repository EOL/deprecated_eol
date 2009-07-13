class AddLinkedDescriptionToDataObjects < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute('alter table data_objects add `description_linked` text NULL default NULL after `description`')
  end
  
  def self.down
    remove_column :data_objects, :description_linked
  end
end
