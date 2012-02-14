class Taxa::MediaController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry, :update_user_content_level

  def index
    @page = params[:page] ||= 1
    @per_page = params[:per_page] ||= $MAX_IMAGES_PER_PAGE
    @per_page = 100 if @per_page.to_i > 100
    @sort_by = params[:sort_by] ||= 'status'
    @type = params[:type] ||= ['all']
    @type = ['all'] if @type.include?('all')
    @status = params[:status] ||= ['all']
    @status = ['all'] if @status.include?('all')
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
        filter_by = ''
      else
        search_statuses = ['trusted', 'unreviewed']
        visibility_statuses = ['visible']
        filter_by = 'visible'
      end
    else
      search_statuses = @status
    end

    @media = EOL::Solr::DataObjects.search_with_pagination(@taxon_concept.id, {
      :page => @page,
      :per_page => @per_page,
      :sort_by => @sort_by,
      :data_type_ids => data_type_ids,
      :vetted_types => search_statuses,
      :visibility_types => visibility_statuses,
      :ignore_maps => true,
      :ignore_translations => true,
      :filter => filter_by,
      :filter_hierarchy_entry => @selected_hierarchy_entry
    })

    # There should not be an older revision of exemplar image on the media tab. But recently there were few cases found.
    # Replace older revision of the exemplar image from media with the latest published revision.
    unless @media.blank?
      @media.map!{ |m| (m.guid == @exemplar_image.guid && m.id != @exemplar_image.id) ? @exemplar_image : m } unless @exemplar_image.nil?
    end

    DataObject.preload_associations(@media, [:users_data_object, { :data_objects_hierarchy_entries => :hierarchy_entry },
      :curated_data_objects_hierarchy_entries])

    DataObject.preload_associations(@media, :translations , :conditions => "data_object_translations.language_id=#{current_user.language_id}")
    @facets = EOL::Solr::DataObjects.get_aggregated_media_facet_counts(@taxon_concept.id,
      :filter_hierarchy_entry => @selected_hierarchy_entry, :user => current_user)
    @current_user_ratings = logged_in? ? current_user.rating_for_object_guids(@media.collect{ |m| m.guid }) : {}
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @assistive_section_header = I18n.t(:assistive_media_header)
    if @selected_hierarchy_entry
      @rel_canonical_href = taxon_hierarchy_entry_media_url(@taxon_concept, @selected_hierarchy_entry, :page => rel_canonical_href_page_number(@media))
      @rel_prev_href = rel_prev_href_params(@media) ? taxon_hierarchy_entry_media_url(@rel_prev_href_params) : nil
      @rel_next_href = rel_next_href_params(@media) ? taxon_hierarchy_entry_media_url(@rel_next_href_params) : nil
    else
      @rel_canonical_href = taxon_media_url(@taxon_concept, :page => rel_canonical_href_page_number(@media))
      @rel_prev_href = rel_prev_href_params(@media) ? taxon_media_url(@rel_prev_href_params) : nil
      @rel_next_href = rel_next_href_params(@media) ? taxon_media_url(@rel_next_href_params) : nil
    end
    current_user.log_activity(:viewed_taxon_concept_media, :taxon_concept_id => @taxon_concept.id)
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

    object = DataObject.find_by_id(data_object_id)
    log_action(@taxon_concept, object, :choose_exemplar)

    store_location(params[:return_to] || request.referer)
    redirect_back_or_default taxon_media_path params[:taxon_concept_id]
  end

end
