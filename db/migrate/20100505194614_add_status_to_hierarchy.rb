class AddStatusToHierarchy < EOL::DataMigration
  
  def self.up
    add_column :hierarchies, :resource_status_id, :integer, :null => true
  end

  def self.down
    remove_column :hierarchies, :resource_status_id
  end
end
