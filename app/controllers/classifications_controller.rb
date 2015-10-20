class ClassificationsController < ApplicationController

  # Sorry, another beast of a method that handles many different things... because there's necessarily only one form.
  def create
    @debug = false
    debug '#create'
    @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
    @target_params = {all: 1} # Show all classifications after any operation that comes here.
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
    debug '#split'
    # They may have (and often have) selected more to move...
    add_entries_to_session if params[:split_hierarchy_entry_id]
    if session[:split_hierarchy_entry_id].length > 1
      clear_entries_from_session
      flash[:error] = I18n.t(:classifications_split_one_classification_only)
    else
      @target_params[:confirm] = 'split' # hard-coded string, no need to translate.
    end
  end

  # They have a list of classifications they want to merge into this taxon concept.
  def merge
    debug '#merge'
    if he_id = additional_confirm_required_on
      flash[:warning] = I18n.t(:classifications_merge_additional_confirm_required)
      @target_params[:providers_match] = he_id
    else
      keep_confirmations
      @target_params[:move_to] = @taxon_concept.id
      return exemplar('merge', nil) if this_is_a_merge?
      return_to_source_taxon
      @target_params[:confirm] = 'merge' # hard-coded string, no need to translate.
    end
  end

  def cancel_split
    debug '#cancel_split'
    clear_entries_from_session
    flash[:notice] = I18n.t(:split_cancelled)
  end

  def add
    debug '#add'
    if params[:split_hierarchy_entry_id]
      add_entries_to_session
      flash[:notice] = I18n.t(:added_classifications_ready)
    else
      # TODO - generalize this check/error with #split and #merge
      flash[:notice] = I18n.t(:no_classificaitons_selected)
    end
  end

  def remove(which)
    debug "#remove(#{which})"
    session[:split_hierarchy_entry_id].delete_if {|id| id.to_s == which.to_s } if session[:split_hierarchy_entry_id]
  end

  def exemplar(type, which)
    debug "#remove(#{type}, #{which})"
    catch_classification_errors do
      if type == 'split'
        @taxon_concept.split_classifications(session[:split_hierarchy_entry_id], exemplar_id: which,
                                             user: current_user)
        complete_exemplar_request('split')
      elsif type == 'merge'
        target_taxon_concept = taxon_concept_from_session
        @taxon_concept.merge_classifications(session[:split_hierarchy_entry_id], with: target_taxon_concept,
                                             forced: !params[:additional_confirm].nil?, exemplar_id: which,
                                             user: current_user)
        complete_exemplar_request('merge', taxon_concept: target_taxon_concept)
      else
        flash[:warning] = I18n.t(:error_exemplar_chosen_with_invalid_action)
      end
    end
  end

  def prefer
    debug '#prefer'
    preferred_entry =
      CuratedTaxonConceptPreferredEntry.best_classification(taxon_concept_id: @taxon_concept.id,
                                                            hierarchy_entry_id: params[:hierarchy_entry_id],
                                                            user_id: current_user.id)
    # This at least clears out the caches for the titles of all images that might use the scientific name:
    @taxon_concept.images_from_solr.each { |img| DataObjectCaching.clear(img) }
    auto_collect(@taxon_concept) # SPG asks for all curation to add the item to their watchlist.
    CuratorActivityLog.log_preferred_classification(preferred_entry, user: current_user)
  end

  def params_exemplar
    debug '#params_exemplar'
    params.keys.each do |key|
      return $1 if key =~ /^exemplar_(\d+)$/
    end
    return nil
  end

  def params_to_remove
    debug '#params_to_remove'
    params.keys.each do |key|
      return $1 if key =~ /^remove_(\d+)$/
    end
    return nil
  end

  # Sorry this is slightly obfuscated, but it's mostly just forcing everything into an array, putting that array in
  # the session, and then (usefully) returning an array of objects to be manipulated or queried. It's okay to call
  # this multiple times (though it could be *slightly* expensive)...
  def add_entries_to_session
    debug '#add_entries_to_session'
    session[:split_hierarchy_entry_id] = [Array(session[:split_hierarchy_entry_id]) +
      Array(params[:split_hierarchy_entry_id])].flatten.compact.uniq
    Array(HierarchyEntry.find(session[:split_hierarchy_entry_id]))
  end

  def taxon_concept_from_session
    debug '#taxon_concept_from_session'
    hierarchy_entries = add_entries_to_session
    @taxon_concept_from_session =
      if hierarchy_entries.nil? || hierarchy_entries.empty?
        nil
      else
        hierarchy_entries.first.taxon_concept
      end
    @taxon_concept_from_session
  end

  def keep_confirmations
    debug '#keep_confirmations'
    @target_params[:additional_confirm] = 1 if params[:additional_confirm]
  end

  def this_is_a_merge?
    debug '#this_is_a_merge?'
    taxon_concept_from_session && taxon_concept_from_session.all_published_entries?(session[:split_hierarchy_entry_id])
  end

  def return_to_source_taxon
    debug '#return_to_source_taxon'
    @taxon_concept = taxon_concept_from_session if taxon_concept_from_session
  end

  def additional_confirm_required_on
    debug '#additional_confirm_required_on'
    return false if params[:additional_confirm] # They already did the confirmation.
    @taxon_concept.providers_match_on_merge(Array(HierarchyEntry.find(session[:split_hierarchy_entry_id])))
  end

  def debug(what)
    return false unless @debug
    logger.error "*" * 100 unless @lined
    @lined = true
    logger.error "** #{what}"
  end

  def catch_classification_errors(&block)
    debug '#catch_classification_errors'
    begin
      yield
    rescue EOL::Exceptions::CannotMergeClassificationsToSelf
      flash[:error] = I18n.t(:classifications_edit_cancelled_merge_to_self)
    rescue EOL::Exceptions::ClassificationsLocked
      flash[:error] = I18n.t(:classifications_edit_cancelled_busy)
    rescue EOL::Exceptions::ProvidersMatchOnMerge => e
      flash[:warning] = I18n.t(:classifications_merge_additional_confirm_required)
      @target_params[:providers_match] = e.message # NOTE - a little wonky to pass the ID in the message.  :|
      @target_params[:exemplar] = which
    rescue EOL::Exceptions::TooManyDescendantsToCurate => e
      flash[:error] = I18n.t(:too_many_descendants_to_curate_with_count, count: e.message) # Also wonky
    end
  end

  def collect_all_entries_and(taxon_concept = nil)
    debug '#collect_all_entries'
    add_entries_to_session.each do |entry|
      auto_collect(@taxon_concept)
      auto_collect(taxon_concept) if taxon_concept
    end
  end

  def clear_entries_from_session
    debug '#clear_entries_from_session'
    session[:split_hierarchy_entry_id] = nil
  end

  def complete_exemplar_request(type, options = {})
    debug "#complete_exemplar_request(#{type}#{options[:target_taxon_concept] ? ' (taxon_concept given)' : ''})"
    flash[:warning] = I18n.t("#{type}_pending") # type is either 'merge' or 'split'
    collect_all_entries_and(options[:taxon_concept])
    clear_entries_from_session
  end

end
