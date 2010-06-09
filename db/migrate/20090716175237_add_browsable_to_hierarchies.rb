class AddBrowsableToHierarchies < EOL::DataMigration

    def self.up
      add_column :hierarchies, :browsable, :integer
    end

    def self.down
      remove_column :hierarchies, :browsable
    end
  end
