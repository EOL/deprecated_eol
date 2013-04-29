class CuratedTaxonConceptPreferredEntry < ActiveRecord::Base
  belongs_to :taxon_concept
  belongs_to :hierarchy_entry
  belongs_to :user

  def self.best_classification(options = {})
    CuratedTaxonConceptPreferredEntry.destroy_all(taxon_concept_id: options[:taxon_concept_id])
    ctcpe = CuratedTaxonConceptPreferredEntry.create(taxon_concept_id: options[:taxon_concept_id],
                                                     hierarchy_entry_id: options[:hierarchy_entry_id],
                                                     user_id: options[:user_id])
    TaxonConceptPreferredEntry.destroy_all(taxon_concept_id: options[:taxon_concept_id])
    TaxonConceptPreferredEntry.create(taxon_concept_id: options[:taxon_concept_id],
                                      hierarchy_entry_id: options[:hierarchy_entry_id])
    ctcpe
  end

end
