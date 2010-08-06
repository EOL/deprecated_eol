class AddHeIndexToTaxa < EOL::DataMigration

  def self.up
    add_index :taxa, :hierarchy_entry_id
  end
  
  def self.down
    remove_index :taxa, :column => :hierarchy_entry_id
  end
end
