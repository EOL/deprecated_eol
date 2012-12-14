class Taxa::MediaController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @page = params[:page] ||= 1
    @per_page = params[:per_page] ||= $MAX_IMAGES_PER_PAGE
    @per_page = 100 if @per_page.to_i > 100
    @sort_by = params[:sort_by] ||= 'status'
    @type = params[:type] ||= ['all']
    @type = ['all'] if @type.include?('all')
    @type = @type.values if @type.is_a?(Hash)
    @status = params[:status] ||= ['all']
    @status = ['all'] if @status.include?('all')
    @status = @status.values if @status.is_a?(Hash)
    @exemplar_image = @taxon_concept.exemplar_or_best_image_from_solr(@selected_hierarchy_entry)

    data_type_ids = []
    ['image', 'video', 'sound'].each do |t|
      next unless @type.include?(t)
      if t == 'video'
        data_type_ids |= DataType.video_type_ids
      elsif data_type = DataType.cached_find_translated(:label, t, 'en')
        data_type_ids |= [data_type.id]
      end
    end
    if data_type_ids.empty?
      data_type_ids = DataType.image_type_ids + DataType.video_type_ids + DataType.sound_type_ids
    end

    if @status == ['all']
      if current_user.is_curator?
        search_statuses = ['trusted', 'unreviewed', 'untrusted']
        visibility_statuses = ['visible', 'invisible']
      else
        search_statuses = ['trusted', 'unreviewed']
        visibility_statuses = ['visible']
      end
    else
      search_statuses = @status
    end

    @media = @taxon_concept.data_objects_from_solr({
      :page => @page,
      :per_page => @per_page,
      :sort_by => @sort_by,
      :data_type_ids => data_type_ids,
      :vetted_types => search_statuses,
      :visibility_types => visibility_statuses,
      :ignore_translations => true,
      :filter_hierarchy_entry => @selected_hierarchy_entry,
      :return_hierarchically_aggregated_objects => true,
      :skip_preload => true,
      :preload_select => { :data_objects => [ :id, :guid, :language_id, :data_type_id, :created_at ] }
    })

    # There should not be an older revision of exemplar image on the media tab. But recently there were few cases found.
    # Replace older revision of the exemplar image from media with the latest published revision.
    unless @media.blank?
      @media.map!{ |m| (m.guid == @exemplar_image.guid && m.id != @exemplar_image.id) ? @exemplar_image : m } unless @exemplar_image.nil?
    end
    
    DataObject.replace_with_latest_versions!(@media, :language_id => current_language.id)
    includes = [ { :data_objects_hierarchy_entries => [ { :hierarchy_entry => [ :name, :hierarchy, { :taxon_concept => :flattened_ancestors } ] }, :vetted, :visibility ] } ]
    includes << { :all_curated_data_objects_hierarchy_entries => [ { :hierarchy_entry => [ :name, :hierarchy, { :taxon_concept => :flattened_ancestors } ] }, :vetted, :visibility, :user ] }
    DataObject.preload_associations(@media, includes)
    DataObject.preload_associations(@media, :users_data_object)
    DataObject.preload_associations(@media, :language)
    DataObject.preload_associations(@media, :mime_type)
    DataObject.preload_associations(@media, :translations , :conditions => "data_object_translations.language_id=#{current_language.id}")
    @facets = EOL::Solr::DataObjects.get_aggregated_media_facet_counts(@taxon_concept.id,
      :filter_hierarchy_entry => @selected_hierarchy_entry, :user => current_user)
    @current_user_ratings = logged_in? ? current_user.rating_for_object_guids(@media.collect{ |m| m.guid }) : {}
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @assistive_section_header = I18n.t(:assistive_media_header)
    if @selected_hierarchy_entry
      @rel_canonical_href = taxon_entry_media_url(@taxon_concept, @selected_hierarchy_entry, :page => rel_canonical_href_page_number(@media))
      @rel_prev_href = rel_prev_href_params(@media) ? taxon_entry_media_url(@rel_prev_href_params) : nil
      @rel_next_href = rel_next_href_params(@media) ? taxon_entry_media_url(@rel_next_href_params) : nil
    else
      @rel_canonical_href = taxon_media_url(@taxon_concept, :page => rel_canonical_href_page_number(@media))
      @rel_prev_href = rel_prev_href_params(@media) ? taxon_media_url(@rel_prev_href_params) : nil
      @rel_next_href = rel_next_href_params(@media) ? taxon_media_url(@rel_next_href_params) : nil
    end
    current_user.log_activity(:viewed_taxon_concept_media, :taxon_concept_id => @taxon_concept.id)
    if params[:ajax]
      return render :partial => 'taxa/media/index'
    end
  end

  def set_as_exemplar
    unless current_user && current_user.min_curator_level?(:assistant)
      raise EOL::Exceptions::SecurityViolation, "User does not have set_as_exemplar privileges"
      return
    end
    taxon_concept_id = params[:taxon_id] || params[:taxon_concept_exemplar_image][:taxon_concept_id]
    taxon_concept = TaxonConcept.find(taxon_concept_id.to_i) rescue nil

    unless params[:taxon_concept_exemplar_image].nil? || params[:taxon_concept_exemplar_image][:data_object_id].blank?
      data_object_id = params[:taxon_concept_exemplar_image][:data_object_id]
    end

    unless taxon_concept_id.blank? || data_object_id.blank?
      TaxonConceptExemplarImage.set_exemplar(taxon_concept, data_object_id)
    end

    @data_object = DataObject.find_by_id(data_object_id)
    log_action(@taxon_concept, @data_object, :choose_exemplar_image)

    store_location(params[:return_to] || request.referer)
    redirect_back_or_default taxon_media_path(taxon_concept_id)
  end

protected
  def meta_description
    @meta_description ||= t(".meta_description#{scoped_variables_for_translations[:preferred_common_name] ? '_with_common_name' : ''}#{@media.blank? ? '_no_data' : ''}", scoped_variables_for_translations.dup)
  end

end
