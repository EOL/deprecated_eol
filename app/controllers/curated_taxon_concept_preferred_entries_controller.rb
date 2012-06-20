class CuratedTaxonConceptPreferredEntriesController < ApplicationController

  # Sorry, another Beast of a method that handles many different things... because there's necessarily only one form.
  def create
    @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
    @target_params = {}
    if current_user.min_curator_level?(:master) && params[:split]
      split
    elsif current_user.min_curator_level?(:master) && params[:merge]
      merge
    elsif current_user.min_curator_level?(:master) && params[:cancel_split]
      cancel_split
    elsif current_user.min_curator_level?(:master) && params[:move]
      move
    elsif current_user.min_curator_level?(:master) && which = params_to_remove
      remove
    elsif current_user.min_curator_level?(:full) && params[:hierarchy_entry_id]
      prefer
    end
    respond_to do |format|
      format.html do
        redirect_to taxon_names_path(@taxon_concept, @target_params)
      end
    end
  end

private

  # They have a list of HEs they want split into a new taxon concept.
  def split
    @target_params[:all] = 1
  end

  # They have a list of HEs they want to merge into this taxon concept.
  def merge
    hierarchy_entries = Array(HierarchyEntry.find(params[:split_hierarchy_entry_id]))
    @taxon_concept = hierarchy_entries.first.taxon_concept # This will redirect them to the right names tab.
    @target_params[:all] = 1
  end

  def cancel_split
    session[:split_hierarchy_entry_id] = nil
    flash[:notice] = I18n.t(:split_cancelled)
    @target_params[:all] = 1
  end

  # They want to store selected HEs for later move...
  def move
    if params[:split_hierarchy_entry_id]
      hierarchies = Array(session[:split_hierarchy_entry_id]) + Array(params[:split_hierarchy_entry_id])
      session[:split_hierarchy_entry_id] = hierarchies.uniq
      flash[:notice] = I18n.t(:move_entries_ready)
    else
      flash[:notice] = I18n.t(:no_classificaitons_selected)
    end
    @target_params[:all] = 1
  end

  def remove
    session[:split_hierarchy_entry_id].delete_if {|id| id.to_s == which.to_s } if session[:split_hierarchy_entry_id]
    @target_params[:all] = 1
  end

  # They have selected a hierarchy entry to represent the best classification for this page.
  def prefer
    @hierarchy_entry = HierarchyEntry.find(params[:hierarchy_entry_id])
    CuratedTaxonConceptPreferredEntry.delete_all("taxon_concept_id = #{@taxon_concept.id}")
    ctcpe = CuratedTaxonConceptPreferredEntry.create(:taxon_concept_id => @taxon_concept.id,
                                                     :hierarchy_entry_id => @hierarchy_entry.id,
                                                     :user_id => current_user.id)
    tcpe = TaxonConceptPreferredEntry.find_by_taxon_concept_id(@taxon_concept.id)
    if tcpe
      tcpe.update_attribute(:hierarchy_entry_id, @hierarchy_entry.id)
    else 
      TaxonConceptPreferredEntry.create(:taxon_concept_id   => @taxon_concept.id,
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

  def params_to_remove
    params.keys.each do |key|
      return $1 if key =~ /^remove_(\d+)$/
    end
  end

end
