class AddDwcArchiveToResources < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute('alter table resources add dwc_archive_url varchar(255) default NULL after `metadata_url`')
    execute('alter table resources add dwc_hierarchy_id int(10) unsigned default NULL after `hierarchy_id`')
  end
  
  def self.down
    remove_column :resources, :dwc_archive_url
    remove_column :resources, :dwc_hierarchy_id
  end
end
