class AddRichnessToTaxonConceptMetrics < ActiveRecord::Migration
  def self.up
    add_column :taxon_concept_metrics, :richness_score, :float
  end

  def self.down
    remove_column :taxon_concept_metrics, :richness_score
  end
end
