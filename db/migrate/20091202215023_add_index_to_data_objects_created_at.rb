class AddIndexToDataObjectsCreatedAt < EOL::DataMigration
  
  def self.up
    execute("create index created_at on data_objects (created_at)")
  end
  
  def self.down
    remove_index :data_objects, :name => 'created_at'
  end
end
