class AddLinkedDescriptionToDataObjects < EOL::DataMigration
  
  def self.up
    execute('alter table data_objects add `description_linked` text NULL default NULL after `description`')
  end
  
  def self.down
    remove_column :data_objects, :description_linked
  end
end
