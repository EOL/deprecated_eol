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

    @media = @taxon_page.media(
      :page => @page,
      :per_page => @per_page,
      :sort_by => @sort_by,
      :data_type_ids => data_type_ids,
      :vetted_types => search_statuses,
      :visibility_types => visibility_statuses
    )
    @taxon_page.preload_details

    @facets = @taxon_page.facets
    @current_user_ratings = logged_in? ? current_user.rating_for_object_guids(@media.collect{ |m| m.guid }) : {}
    @assistive_section_header = I18n.t(:assistive_media_header)
    set_canonical_urls(:for => @taxon_page, :paginated => @media, :url_method => :taxon_media_url)
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
