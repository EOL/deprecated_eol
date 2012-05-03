class CuratedTaxonConceptPreferredEntriesController < ApplicationController

  def create
    @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
    @hierarchy_entry = HierarchyEntry.find(params[:hierarchy_entry_id])
    if current_user.min_curator_level?(:full)
      CuratedTaxonConceptPreferredEntry.delete_all("taxon_concept_id = #{@taxon_concept.id}")
      ctcpe = CuratedTaxonConceptPreferredEntry.create(:taxon_concept_id => @taxon_concept.id,
                                                       :hierarchy_entry_id => @hierarchy_entry.id,
                                                       :user_id => current_user.id)
      tcpe = TaxonConceptPreferredEntry.find_by_taxon_concept_id(@taxon_concept.id)
      if tcpe
        tcpe.update_attribute(:hierarchy_entry_id, @hierarchy_entry.id)
      else 
        TaxonConceptPreferredEntry.create(:taxon_concept_id => @taxon_concept.id,
                                          :hierarchy_entry_id => @hierarchy_entry.id)
      end
      auto_collect(@taxon_concept) # SPG asks for all curation to add the item to their watchlist.
      CuratorActivityLog.create(
        :user => current_user,
        :changeable_object_type => ChangeableObjectType.curated_taxon_concept_preferred_entry,
        :object_id => ctcpe.id,
        :hierarchy_entry_id => @hierarchy_entry.id,
        :taxon_concept_id => @taxon_concept.id,
        :activity => Activity.preferred_classification,
        :created_at => 0.seconds.from_now
      )
    end
    respond_to do |format|
      format.html do
        redirect_to taxon_names_path(@taxon_concept)
      end
    end
  end

end
