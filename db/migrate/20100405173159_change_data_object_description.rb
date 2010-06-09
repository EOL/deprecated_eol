class ChangeDataObjectDescription < EOL::DataMigration
  
  def self.up
    execute('alter table data_objects modify `description` mediumtext NOT NULL')
    execute('alter table data_objects modify `description_linked` mediumtext')
  end
  
  def self.down
    execute('alter table data_objects modify `description` text NOT NULL')
    execute('alter table data_objects modify `description_linked` text')
  end
end
