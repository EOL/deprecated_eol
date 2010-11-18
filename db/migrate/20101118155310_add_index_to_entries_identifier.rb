class AddIndexToEntriesIdentifier < EOL::DataMigration
  def self.up
    execute('create index identifier on hierarchy_entries(identifier)')
  end

  def self.down
    remove_index :hierarchy_entries, :name => 'identifier'
  end
end
