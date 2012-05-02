class CuratedTaxonConceptPreferredEntriesController < ApplicationController

  def create
    @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
    @hierarchy_entry = HierarchyEntry.find(params[:hierarchy_entry_id])
    if current_user.min_curator_level?(:full)
      begin
        CuratedTaxonConceptPreferredEntry.create(:taxon_concept_id => @taxon_concept.id,
                                                 :hierarchy_entry_id => @hierarchy_entry.id,
                                                 :user_id => current_user)
      rescue ActiveRecord::StatementInvalid
        # They have marked this as preferred before, but we don't care.
      end
      tcpe = TaxonConceptPreferredEntry.find_by_taxon_concept_id(@taxon_concept.id)
      if tcpe
        tcpe.update_attribute(:hierarchy_entry_id, @hierarchy_entry.id)
      else 
        TaxonConceptPreferredEntry.create(:taxon_concept_id => @taxon_concept.id,
                                          :hierarchy_entry_id => @hierarchy_entry.id)
      end
      # TODO - Log the event in activity logs.
      respond_to do |format|
        format.html do
          redirect_to taxon_names_path(@taxon_concept)
        end
      end
    else 
      # TODO - raise exception... but, really, they couldn't get here if they weren't a curator... so, low-prio.
    end
  end

end
