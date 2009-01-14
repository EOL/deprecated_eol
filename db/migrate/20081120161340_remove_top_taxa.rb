class RemoveTopTaxa < ActiveRecord::Migration

  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    execute "DROP TABLE IF EXISTS top_taxa"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration.new("This dropped the top_taxa table.  It's gone.")
  end

end
