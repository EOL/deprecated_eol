class AddMapToTaxonConceptMetrics < ActiveRecord::Migration
  def self.up
    add_column :taxon_concept_metrics, :map_total, :mediumint
    add_column :taxon_concept_metrics, :map_trusted, :mediumint
    add_column :taxon_concept_metrics, :map_untrusted, :mediumint
    add_column :taxon_concept_metrics, :map_unreviewed, :mediumint
  end

  def self.down
    remove_column :taxon_concept_metrics, :map_total
    remove_column :taxon_concept_metrics, :map_trusted
    remove_column :taxon_concept_metrics, :map_untrusted
    remove_column :taxon_concept_metrics, :map_unreviewed
  end
end


