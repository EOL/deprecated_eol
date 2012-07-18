class ClassificationsController < ApplicationController

  # Sorry, another beast of a method that handles many different things... because there's necessarily only one form.
  def create
    @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
    @target_params = {}
    master = current_user.min_curator_level?(:master)
    if master && params[:split]
      split
    elsif master && params[:merge]
      merge
    elsif master && params[:cancel_split]
      cancel_split
    elsif master && params[:add]
      add
    elsif master && which = params_to_remove
      remove(which)
    elsif master && which = params_exemplar
      exemplar(params[:confirm], which)
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

  # They have a list of classifications they want split into a new taxon concept.
  def split
    # They may have (and often have) selected more to move...
    add_entries_to_session if params[:split_hierarchy_entry_id]
    @target_params[:confirm] = 'split' # hard-coded string, no need to translate.
    @target_params[:all] = 1
  end

  # They have a list of classifications they want to merge into this taxon concept.
  def merge
    if (!params[:additional_confirm]) &&
      he_id = @taxon_concept.providers_match_on_merge(Array(HierarchyEntry.find(session[:split_hierarchy_entry_id])))
      flash[:warn] = I18n.t(:classifications_merge_additional_confirm_required)
      @target_params[:providers_match] = he_id
    else
      # If they have already confirmed this, don't confirm it again:
      @target_params[:additional_confirm] = 1 if params[:additional_confirm]
      @target_params[:move_to] = @taxon_concept.id
      # Just go ahead and do the merge without asking for an exemplar, if it's ALL the entries from that page:
      return exemplar('merge', nil) if taxon_concept_from_session.all_published_entries?(session[:split_hierarchy_entry_id])
      @target_params[:confirm] = 'merge' # hard-coded string, no need to translate.
    end
    @target_params[:all] = 1
  end

  def cancel_split
    session[:split_hierarchy_entry_id] = nil
    flash[:notice] = I18n.t(:split_cancelled)
    @target_params[:all] = 1
  end

  def add
    if params[:split_hierarchy_entry_id]
      add_entries_to_session
      flash[:notice] = I18n.t(:added_classifications_ready)
    else
      # TODO - generalize this check/error with #split and #merge
      flash[:notice] = I18n.t(:no_classificaitons_selected)
    end
    @target_params[:all] = 1
  end

  def remove(which)
    session[:split_hierarchy_entry_id].delete_if {|id| id.to_s == which.to_s } if session[:split_hierarchy_entry_id]
    @target_params[:all] = 1
  end

  def exemplar(type, which)
    done = false
    target_taxon_concept = nil
    begin
      if type == 'split'
        @taxon_concept.split_classifications(session[:split_hierarchy_entry_id], :exemplar_id => which, :notify => current_user.id)
        flash[:warning] = I18n.t(:split_pending)
        done = true
      elsif type == 'merge'
        target_taxon_concept = taxon_concept_from_session
        @taxon_concept.merge_classifications(session[:split_hierarchy_entry_id], :with => target_taxon_concept,
                                             :additional_confirm => params[:additional_confirm], :exemplar_id => which,
                                             :notify => current_user.id)
        flash[:warning] = I18n.t(:merge_pending)
        done = true
      else
        # TODO - error, we don't have a split or merge in params... (low priority; unlikely)
      end
    rescue EOL::Exceptions::CannotMergeClassificationsToSelf
      flash[:error] = I18n.t(:classifications_edit_cancelled_merge_to_self)
    rescue EOL::Exceptions::ClassificationsLocked
      flash[:error] = I18n.t(:classifications_edit_cancelled_busy)
    rescue EOL::Exceptions::ProvidersMatchOnMerge => e
      flash[:warn] = I18n.t(:classifications_merge_additional_confirm_required)
      @target_params[:providers_match] = e.message # NOTE - a little wonky to pass the ID in the message.  :|
      @target_params[:exemplar] = which
    end
    if done
      add_entries_to_session.each do |entry|
        auto_collect(@taxon_concept)
        auto_collect(target_taxon_concept) if target_taxon_concept
        log_activity(:target_taxon_concept_id => target_taxon_concept ? target_taxon_concept.id : nil,
                     :entry => entry, :type => "#{type}_classifications")
      end
      session[:split_hierarchy_entry_id] = nil
      @target_params[:pending] = 1
    end
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

  def params_exemplar
    params.keys.each do |key|
      return $1 if key =~ /^exemplar_(\d+)$/
    end
    return nil
  end

  def params_to_remove
    params.keys.each do |key|
      return $1 if key =~ /^remove_(\d+)$/
    end
    return nil
  end

  # Sorry this is slightly obfuscated, but it's mostly just forcing everything into an array, putting that array in
  # the session, and then (usefully) returning an array of objects to be manipulated or queried. It's okay to call
  # this multiple times (though it could be *slightly* expensive)...
  def add_entries_to_session
    session[:split_hierarchy_entry_id] = [Array(session[:split_hierarchy_entry_id]) +
      Array(params[:split_hierarchy_entry_id])].flatten.compact.uniq
    Array(HierarchyEntry.find(session[:split_hierarchy_entry_id]))
  end

  def taxon_concept_from_session
    hierarchy_entries = add_entries_to_session
    return hierarchy_entries.first.taxon_concept # This will redirect them to the right names tab.
  end

  def log_activity(options)
    CuratorActivityLog.create(
      :user => current_user,
      :hierarchy_entry_id => options[:entry].id,
      :taxon_concept_id => @taxon_concept.id,
      :changeable_object_type => ChangeableObjectType.taxon_concept,
      :object_id => options[:target_taxon_concept_id] || @taxon_concept.id,
      :activity => Activity.send(options[:type].to_sym),
      :created_at => 0.seconds.from_now
    )
  end

end
