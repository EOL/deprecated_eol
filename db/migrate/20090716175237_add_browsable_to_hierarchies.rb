class AddBrowsableToHierarchies < ActiveRecord::Migration
    def self.database_model
      return "SpeciesSchemaModel"
    end

    def self.up
      add_column :hierarchies, :browsable, :integer
    end

    def self.down
      remove_column :hierarchies, :browsable
    end
  end