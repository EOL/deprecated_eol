class AddIdentifierToDataObjects < EOL::DataMigration
  
  def self.up
    #Query OK, 6022736 rows affected (33 min 2.74 sec)
    execute('alter table data_objects add `identifier` varchar(255) NULL after `guid`')
    #Query OK, 5506040 rows affected (1 hour 28 min 45.68 sec)
    execute('update ignore data_objects do join data_objects_taxa dot on (do.id=dot.data_object_id) set do.identifier=dot.identifier where dot.identifier!=""')
    #Query OK, 6022736 rows affected (37 min 4.32 sec)
    execute('create index identifier on data_objects(identifier)')
    remove_column :data_objects_taxa, :identifier
  end
  
  def self.down
    execute('alter table data_objects_taxa add `identifier` varchar(255) NOT NULL after `data_object_id`')
    execute('update ignore data_objects do join data_objects_taxa dot on (do.id=dot.data_object_id) set dot.identifier=do.identifier')
    remove_column :data_objects, :identifier
  end
end
