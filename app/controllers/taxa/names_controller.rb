class Taxa::NamesController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :set_vet_options, only: [:common_names, :vet_common_name]
  before_filter :authentication_for_names, only: [ :create, :update, :delete ]
  before_filter :load_hierarchy_entries, only: [ :related_names, :common_names, :synonyms ]
  before_filter :parse_classification_controller_params, only: :index

  # TODO - there's too much logic here. Consider a Classifications class to use as presenter.
  def index

    session[:split_hierarchy_entry_id] = params[:split_hierarchy_entry_id] if params[:split_hierarchy_entry_id]
    params[:all] = 1 if session[:split_hierarchy_entry_id] && !session[:split_hierarchy_entry_id].blank?
    if params[:all]
      @hierarchy_entries = @taxon_concept.deep_published_sorted_hierarchy_entries
      @other_hierarchy_entries = []
    else 
      @hierarchy_entries = @taxon_concept.deep_published_browsable_hierarchy_entries
      @other_hierarchy_entries = @taxon_concept.deep_published_nonbrowsable_hierarchy_entries
    end
    HierarchyEntry.preload_associations(@hierarchy_entries,
      [ { hierarchy: [ { resource: :content_partner }, :dwc_resource ] }, :rank, :flat_ancestors ])

    # preloading the names for the current nodes and their ancestors. Children and sublings will be loaded later in
    # the views which is more efficient as we can preload only the first $max_children of each, sorted by name. It
    # is not possible to get for example "the first 10 children, alphabetically, for these 15 entries". That must be
    # done for each entry individually
    HierarchyEntry.preload_associations((@hierarchy_entries + @hierarchy_entries.collect(&:flat_ancestors)).flatten, :name)

    @pending_moves = HierarchyEntryMove.pending.find_all_by_hierarchy_entry_id(@hierarchy_entries)

    @assistive_section_header = I18n.t(:assistive_names_classifications_header)
    common_names_count
    respond_to do |format|
      format.html { render action: 'classifications' }
      # TODO - this reloads the WHOLE tab... we should probably break it down a bit.
      format.js {}
    end
  end

  # GET /pages/:taxon_id/names
  # related names default tab
  def related_names
    @related_names = @taxon_page.related_names
    @rel_canonical_href = taxon_names_url(@taxon_page)
    @assistive_section_header = I18n.t(:assistive_names_related_header)
    common_names_count
  end

  # POST /pages/:taxon_id/names NOTE - this is currently only used to add common_names
  def create
    if params[:commit_add_common_name]
      current_user.add_agent unless current_user.agent
      agent = current_user.agent
      language = Language.find(params[:name][:synonym][:language_id])
      synonym = @taxon_concept.add_common_name_synonym(params[:name][:string],
                agent: agent, language: language, vetted: Vetted.trusted)
      unless synonym.errors.blank?
        flash[:error] = I18n.t(:common_name_exists, name_string: params[:name][:string])
      else
        @taxon_concept.reindex_in_solr
        log_action(@taxon_concept, synonym, :add_common_name)
        expire_taxa([@taxon_concept.id])
      end
    end
    store_location :back
    redirect_back_or_default common_names_taxon_names_path(@taxon_concept)
  end

  # PUT /pages/:taxon_id/names currently only used to update common_names
  def update
    if current_user.is_curator?
      if params[:preferred_name_id]
        name = Name.find(params[:preferred_name_id])
        language = Language.find(params[:language_id])
        @taxon_concept.add_common_name_synonym(name.string, agent: current_user.agent, language: language, preferred: 1, vetted: Vetted.trusted)
        expire_taxa([@taxon_concept.id])
      end
    end
    if !params[:hierarchy_entry_id].blank?
      redirect_to common_names_taxon_entry_names_path(@taxon_concept, params[:hierarchy_entry_id]), status: :moved_permanently
    else
      redirect_to common_names_taxon_names_path(@taxon_concept), status: :moved_permanently
    end
  end

  def delete
    synonym_id = params[:synonym_id].to_i
    category_id = params[:category_id].to_i
    synonym = Synonym.find(synonym_id)
    if synonym && @taxon_concept
      log_action(@taxon_concept, synonym, :remove_common_name)
      tcn = TaxonConceptName.find_by_synonym_id_and_taxon_concept_id(synonym_id, @taxon_concept.id)
      unless current_user.can_delete?(tcn)
        raise EOL::Exceptions::SecurityViolation.new("User with ID=#{current_user.id} does not have edit access to Synonym with ID=#{synonym_id}",
        :missing_delete_access_to_synonym)
      end
      @taxon_concept.delete_common_name(tcn)
      @taxon_concept.reindex_in_solr
    end

    if !params[:hierarchy_entry_id].blank?
      redirect_to common_names_taxon_entry_names_path(@taxon_concept, params[:hierarchy_entry_id]), status: :moved_permanently
    else
      redirect_to common_names_taxon_names_path(@taxon_concept), status: :moved_permanently
    end
  end

  # GET for collection synonyms /pages/:taxon_id/synonyms
  def synonyms
    associations = { published_hierarchy_entries: [ :hierarchy, :name, { scientific_synonyms: [ :synonym_relation, :name ] } ] }
    options = { select: { hierarchy_entries: [ :id, :name_id, :hierarchy_id, :taxon_concept_id ],
                           names: [ :id, :string ],
                           synonym_relations: [ :id ] } }
    TaxonConcept.preload_associations(@taxon_concept, associations, options )
    @assistive_section_header = I18n.t(:assistive_names_synonyms_header)
    @rel_canonical_href = synonyms_taxon_names_url(@taxon_page)
    common_names_count
  end

  # GET for collection common_names /pages/:taxon_id/names/common_names
  def common_names
    @languages = Language.with_iso_639_1.delete_if { |l| l.label.nil? }.sort_by(&:label)
    @languages.collect! { |lang| [view_context.truncate(lang.label.to_s, length: 20), lang.id] }
    @common_names = get_common_names
    @common_names_count = @common_names.collect{|cn| [cn.name.id,cn.language.id]}.uniq.count
    @assistive_section_header = I18n.t(:assistive_names_common_header)
    @rel_canonical_href = common_names_taxon_names_url(@taxon_page)
  end

  def vet_common_name
    language_id = params[:language_id].to_i
    name_id = params[:id].to_i
    vetted = Vetted.find(params[:vetted_id])
    @taxon_concept.vet_common_name(language_id: language_id, name_id: name_id, vetted: vetted, user: current_user)

    synonym = Synonym.find_by_name_id(name_id);
    if synonym
      case vetted.label
      when "Trusted"
        log_action(@taxon_concept, synonym, :trust_common_name)
      when "Inappropriate"
        log_action(@taxon_concept, synonym, :inappropriate_common_name)
      when "Unknown"
        log_action(@taxon_concept, synonym, :unreview_common_name)
      when "Untrusted"
        log_action(@taxon_concept, synonym, :untrust_common_name)
      end
      @taxon_concept.reindex_in_solr
    end

    respond_to do |format|
      format.html do
        if !params[:hierarchy_entry_id].blank?
          redirect_to common_names_taxon_entry_names_path(@taxon_concept, params[:hierarchy_entry_id]), status: :moved_permanently
        else
          redirect_to common_names_taxon_names_path(@taxon_concept), status: :moved_permanently
        end
      end
      format.js do
        # TODO - this is a huge waste of time, but I couldn't come up with a timely solution... we only need ONE set
        # of names, here, not all of them:
        render partial: 'common_names_edit_row', locals: {common_names: get_common_names(name_id: name_id, language_id: language_id),
          language: TranslatedLanguage.find(language_id).label, name_id: name_id }
      end
    end
  end

private

  def get_common_names(options = {})
    @taxon_page.common_names(options)
  end

  def common_names_count
    @common_names_count ||= @taxon_page.common_names_count
  end

  def set_vet_options
    @common_name_vet_options = {I18n.t(:trusted) => Vetted.trusted.id.to_s, I18n.t(:unreviewed) => Vetted.unknown.id.to_s, I18n.t(:untrusted) => Vetted.untrusted.id.to_s}
  end

  def load_hierarchy_entries
    @hierarchy_entries = @taxon_page.hierarchy_entries
  end

  def authentication_for_names
    if ! current_user.is_curator?
      flash[:error] = I18n.t(:insufficient_privileges_to_curate_names)
      store_location params[:return_to] unless params[:return_to].blank?
      redirect_back_or_default common_names_taxon_names_path(@taxon_concept)
    end
  end

  def parse_classification_controller_params
    @confirm_split_or_merge = params[:confirm]
    @providers_match = params[:providers_match]
    @exemplar = params[:exemplar]
    @additional_confirm = params[:additional_confirm]
    @move_to = params[:move_to]
  end

end
