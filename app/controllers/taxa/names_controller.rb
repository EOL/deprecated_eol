class Taxa::NamesController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry
  before_filter :set_vet_options, :only => [:common_names, :vet_common_name]
  before_filter :authentication_for_names, :only => [ :create, :update ]
  before_filter :preload_core_relationships_for_names, :only => [ :index, :common_names, :synonyms ]

  # GET /pages/:taxon_id/names
  # related names default tab
  def index
    if @selected_hierarchy_entry
      @related_names = TaxonConcept.related_names(:hierarchy_entry_id => @selected_hierarchy_entry_id)
      @rel_canonical_href = taxon_hierarchy_entry_names_url(@taxon_concept, @selected_hierarchy_entry)
    else
      @related_names = TaxonConcept.related_names(:taxon_concept_id => @taxon_concept.id)
      @rel_canonical_href = taxon_names_url(@taxon_concept)
    end
    @assistive_section_header = I18n.t(:assistive_names_related_header)
    current_user.log_activity(:viewed_taxon_concept_names_related_names, :taxon_concept_id => @taxon_concept.id)

    # for common names count
    common_names_count
  end

  # POST /pages/:taxon_id/names currently only used to add common_names
  def create
    if params[:commit_add_common_name]
      agent = current_user.agent
      language = Language.find(params[:name][:synonym][:language_id])
      synonym = @taxon_concept.add_common_name_synonym(params[:name][:string],
                :agent => agent, :language => language, :vetted => Vetted.trusted)
      unless synonym.errors.blank?
        flash[:error] = I18n.t(:common_name_exists, :name_string => params[:name][:string])
      else
        @taxon_concept.reindex_in_solr
        log_action(@taxon_concept, synonym, :add_common_name)
        expire_taxa([@taxon_concept.id])
      end
    end
    store_location params[:return_to] unless params[:return_to].blank?
    redirect_back_or_default common_names_taxon_names_path(@taxon_concept)
  end

  # PUT /pages/:taxon_id/names currently only used to update common_names
  def update
    if current_user.is_curator?
      if !params[:preferred_name_id].nil?
        name = Name.find(params[:preferred_name_id])
        language = Language.find(params[:language_id])
        @taxon_concept.add_common_name_synonym(name.string, :agent => current_user.agent, :language => language, :preferred => 1, :vetted => Vetted.trusted)
        expire_taxa([@taxon_concept.id])
      end

      current_user.log_activity(:updated_common_names, :taxon_concept_id => @taxon_concept.id)
    end
    if !params[:hierarchy_entry_id].blank?
      redirect_to common_names_taxon_hierarchy_entry_names_path(@taxon_concept, params[:hierarchy_entry_id]), :status => :moved_permanently
    else
      redirect_to common_names_taxon_names_path(@taxon_concept), :status => :moved_permanently
    end
  end

  # TODO - This needs to add a CuratorActivityLog.
  def delete
    synonym_id = params[:synonym_id].to_i
    category_id = params[:category_id].to_i
    synonym = Synonym.find(synonym_id)
    if synonym && @taxon_concept
      log_action(@taxon_concept, synonym, :remove_common_name)
      tcn = TaxonConceptName.find_by_synonym_id_and_taxon_concept_id(synonym_id, @taxon_concept.id)
      @taxon_concept.delete_common_name(tcn)
      @taxon_concept.reindex_in_solr
    end

    if !params[:hierarchy_entry_id].blank?
      redirect_to common_names_taxon_hierarchy_entry_names_path(@taxon_concept, params[:hierarchy_entry_id]), :status => :moved_permanently
    else
      redirect_to common_names_taxon_names_path(@taxon_concept), :status => :moved_permanently
    end
  end

  # GET for collection synonyms /pages/:taxon_id/synonyms
  def synonyms
    associations = { :published_hierarchy_entries => [ :name, { :scientific_synonyms => [ :synonym_relation, :name ] } ] }
    options = { :select => { :hierarchy_entries => [ :id, :name_id, :hierarchy_id, :taxon_concept_id ],
                           :names => [ :id, :string ],
                           :synonym_relations => [ :id ] } }
    TaxonConcept.preload_associations(@taxon_concept, associations, options )
    @assistive_section_header = I18n.t(:assistive_names_synonyms_header)
    @rel_canonical_href = @selected_hierarchy_entry ?
      synonyms_taxon_hierarchy_entry_names_url(@taxon_concept, @selected_hierarchy_entry) :
      synonyms_taxon_names_url(@taxon_concept)
    current_user.log_activity(:viewed_taxon_concept_names_synonyms, :taxon_concept_id => @taxon_concept.id)

    # for common names count
    common_names_count
  end

  # GET for collection common_names /pages/:taxon_id/names/common_names
  def common_names
    @languages = Language.with_iso_639_1.sort_by{ |l| l.label }
    @languages.collect! {|lang|  [lang.label.to_s.truncate(20), lang.id] }
    @common_names = get_common_names
    @common_names_count = @common_names.collect{|cn| [cn.name.id,cn.language.id]}.uniq.count
    @assistive_section_header = I18n.t(:assistive_names_common_header)
    @rel_canonical_href = @selected_hierarchy_entry ?
      common_names_taxon_hierarchy_entry_names_url(@taxon_concept, @selected_hierarchy_entry) :
      common_names_taxon_names_url(@taxon_concept)
    current_user.log_activity(:viewed_taxon_concept_names_common_names, :taxon_concept_id => @taxon_concept.id)
  end

  # TODO - This needs to add a CuratorActivityLog.
  def vet_common_name
    language_id = params[:language_id].to_i
    name_id = params[:id].to_i
    vetted = Vetted.find(params[:vetted_id])
    @taxon_concept.current_user = current_user
    @taxon_concept.vet_common_name(:language_id => language_id, :name_id => name_id, :vetted => vetted)
    current_user.log_activity(:vetted_common_name, :taxon_concept_id => @taxon_concept.id, :value => name_id)

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
          redirect_to common_names_taxon_hierarchy_entry_names_path(@taxon_concept, params[:hierarchy_entry_id]), :status => :moved_permanently
        else
          redirect_to common_names_taxon_names_path(@taxon_concept), :status => :moved_permanently
        end
      end
      format.js do
        # TODO - this is a huge waste of time, but I couldn't come up with a timely solution... we only need ONE set
        # of names, here, not all of them:
        render :partial => 'common_names_edit_row', :locals => {:common_names => get_common_names(:name_id => name_id, :language_id => language_id),
          :language => TranslatedLanguage.find(language_id).label, :name_id => name_id }
      end
    end
  end

private

  def get_common_names(options = {})
    unknown_id = Language.unknown.id
    if @selected_hierarchy_entry
      names = EOL::CommonNameDisplay.find_by_hierarchy_entry_id(@selected_hierarchy_entry.id, options)
    else
      names = EOL::CommonNameDisplay.find_by_taxon_concept_id(@taxon_concept.id, nil, options)
    end
    common_names = names.select {|n| !n.language.iso_639_1.blank? || !n.language.iso_639_2.blank? }
  end

  def common_names_count
    @common_names_count = get_common_names.collect{|cn| [cn.name.id,cn.language.id]}.uniq.count if @common_names_count.nil?
    @common_names_count
  end

  def set_vet_options
    @common_name_vet_options = {I18n.t(:trusted) => Vetted.trusted.id.to_s, I18n.t(:unreviewed) => Vetted.unknown.id.to_s, I18n.t(:untrusted) => Vetted.untrusted.id.to_s}
  end

  def preload_core_relationships_for_names
    if @selected_hierarchy_entry.blank?
      @hierarchy_entries = @taxon_concept.published_browsable_hierarchy_entries
    else
      @hierarchy_entries =
        @taxon_concept.published_browsable_hierarchy_entries.select {|he| he.id == @selected_hierarchy_entry.id}
    end
  end

  def authentication_for_names
    if ! current_user.is_curator?
      flash[:error] = I18n.t(:insufficient_privileges_to_curate_names)
      store_location params[:return_to] unless params[:return_to].blank?
      redirect_back_or_default common_names_taxon_names_path(@taxon_concept)
    end
  end

end
