class AddPublishedToTaxonConcepts < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute "ALTER TABLE taxon_concepts ADD COLUMN published TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER vetted_id"
  end

  def self.down
    remove_column :taxon_concepts, :published
  end
end