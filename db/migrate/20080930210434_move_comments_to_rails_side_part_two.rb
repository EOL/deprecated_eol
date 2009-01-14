class MoveCommentsToRailsSidePartTwo < ActiveRecord::Migration

  def self.database_model
    return "SpeciesSchemaModel"
  end 

  def self.up
    raise ActiveRecord::IrreversibleMigration.new("REMOVE (or, move) ALL COMMENTS FROM THE DATABASE BEFORE PROCEEDING.") unless
      TaxonConcept.connection.select_value('SELECT COUNT(*) FROM comments').to_i == 0
    drop_table :comments
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration.new("Reversing this migration is too difficult.  Do it yourself.") 
  end

end
