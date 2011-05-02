module EOL
  class DataMigration < ActiveRecord::Migration
    def self.connection
      LegacySpeciesSchemaModel.connection
    end
  end
end

