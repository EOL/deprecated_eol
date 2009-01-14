class AddVettedToTaxonConcepts < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute "ALTER TABLE taxon_concepts ADD COLUMN vetted_id TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER supercedure_id"
  end

  def self.down
    remove_column :taxon_concepts, :vetted_id
  end
end