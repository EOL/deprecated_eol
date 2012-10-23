class CuratedTaxonConceptPreferredEntry < ActiveRecord::Base
  belongs_to :taxon_concept
  belongs_to :hierarchy_entry
  belongs_to :user

  def self.best_classification(options = {})
    CuratedTaxonConceptPreferredEntry.delete_all("taxon_concept_id = #{options[:taxon_concept_id]}")
    ctcpe = CuratedTaxonConceptPreferredEntry.create(:taxon_concept_id => options[:taxon_concept_id],
                                                     :hierarchy_entry_id => options[:hierarchy_entry_id],
                                                     :user_id => options[:user_id])
    tcpe = TaxonConceptPreferredEntry.find_by_taxon_concept_id(options[:taxon_concept_id])
    if tcpe
      tcpe.update_attribute(:hierarchy_entry_id, options[:hierarchy_entry_id])
    else 
      TaxonConceptPreferredEntry.create(:taxon_concept_id   => options[:taxon_concept_id],
                                        :hierarchy_entry_id => options[:hierarchy_entry_id])
    end
    ctcpe
  end

end
