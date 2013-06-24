class CuratedTaxonConceptPreferredEntry < ActiveRecord::Base
  belongs_to :taxon_concept
  belongs_to :hierarchy_entry
  belongs_to :user

  def self.best_classification(options = {})
    # TODO - this is perhaps the opposite of what we "want" to do... we might want this all to be delayed:
    TaxonConceptPreferredEntry.with_master do
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

  def self.for_taxon_concept(taxon_concept)
    curated_preferred_entry = CuratedTaxonConceptPreferredEntry.find_by_taxon_concept_id(taxon_concept.id)
    return nil unless curated_preferred_entry
    entry = curated_preferred_entry.hierarchy_entry
    # if the entry is not published, try to find a published replacement, or return nil. The
    # database record is not updated with the replacement at this point
    unless entry.published?
      # see if there is a published entry in the same hierarchy
      # order each result giving priority to entries with the same :identifier
      if he = HierarchyEntry.where(taxon_concept_id: taxon_concept.id, hierarchy_id: entry.hierarchy_id, published: 1).
                             order("identifier=#{entry.identifier} DESC").limit(1).first
        curated_preferred_entry.hierarchy_entry = he
      elsif entry.hierarchy.hierarchy_group_id > 0
        # see if there is a published entry in the same hierarchy group (e.g. COL 2010, 2011, 2012...)
        if he = HierarchyEntry.where(taxon_concept_id: taxon_concept.id, published: 1).joins(:hierarchy).
                               where("hierarchies.hierarchy_group_id = #{entry.hierarchy.hierarchy_group_id}").
                               order("identifier=#{entry.identifier} DESC").limit(1).first
          curated_preferred_entry.hierarchy_entry = he
        end
      else
        return nil
      end
    end
    curated_preferred_entry
  end

end
