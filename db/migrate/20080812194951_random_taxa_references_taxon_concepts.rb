class RandomTaxaReferencesTaxonConcepts < ActiveRecord::Migration

  # This is the method that makes sure we're in the proper database.  See vendor/plugins/use_db/README for details,
  # but basically it wants the name of a model that calls the "use_db" that you want to mimic.
  def self.database_model
    return "SpeciesSchemaModel"
  end 

  # NOTE this does some find()s with IDs to ensure that your RaondomTaxon model can be in any state (with or without proper
  # relationships).
  def self.up
    add_column :random_taxa, :taxon_concept_id, :integer, :force => true
    RandomTaxon.find(:all).each do |random_entry|
      random_entry.taxon_concept_id = HierarchyEntry.find(random_entry.hierarchy_entry_id).taxon_concept_id
      random_entry.save!
    end
    remove_column :random_taxa, :hierarchy_entry_id
  end

  def self.down
    add_column :random_taxa, :hierarchy_entry_id, :integer 
    RandomTaxon.find(:all).each do |random_entry|
      # Note that this detect() isn't perfect, so we shouldn't REALLY rely on this, but on the other hand, it's not crucial for this
      # purpose.  Ideally, it should have looked for the HE with the highest content level.  Ce la vie.
      random_entry.hierarchy_entry_id = TaxonConcept.find(random_entry.taxon_concept_id).hierarchy_entries.detect {|he| he.hierarchy_id == Hierarchy.default }
      random_entry.save!
    end
    remove_column :random_taxa, :taxon_concept_id
  end
end
