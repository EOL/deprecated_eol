module EOL
  class DataMigration < ActiveRecord::Migration
    def self.connection
      SpeciesSchemaModel.connection
    end
  end
end

