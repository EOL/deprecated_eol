class Taxa::MediaController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid
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
      else
        search_statuses = ['trusted', 'unreviewed']
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
      :visibility_types => 'visible',
      :ignore_maps => true,
      :ignore_translations => true,
      :filter => 'visible',
      :filter_hierarchy_entry => @selected_hierarchy_entry
    })
    DataObject.preload_associations(@media, [:users_data_object, { :data_objects_hierarchy_entries => :hierarchy_entry },
      :curated_data_objects_hierarchy_entries])

    @facets = EOL::Solr::DataObjects.get_aggregated_media_facet_counts(@taxon_concept.id,
      :filter_hierarchy_entry => @selected_hierarchy_entry, :user => current_user)
    @current_user_ratings = logged_in? ? current_user.rating_for_object_guids(@media.collect{ |m| m.guid }) : {}
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @assistive_section_header = I18n.t(:assistive_media_header)
    current_user.log_activity(:viewed_taxon_concept_media, :taxon_concept_id => @taxon_concept.id)
  end

  def set_as_exemplar
    taxon_concept_id = params[:taxon_id] || params[:taxon_concept_exemplar_image][:taxon_concept_id]
    taxon_concept = TaxonConcept.find(taxon_concept_id.to_i) rescue nil

    unless params[:taxon_concept_exemplar_image].nil? || params[:taxon_concept_exemplar_image][:data_object_id].blank?
      data_object_id = params[:taxon_concept_exemplar_image][:data_object_id]
    end

    unless taxon_concept_id.blank? || data_object_id.blank?
      TaxonConceptExemplarImage.set_exemplar(taxon_concept, data_object_id)
    end

    store_location(params[:return_to] || request.referer)
    redirect_back_or_default taxon_media_path params[:taxon_concept_id]
  end

private

  def redirect_if_superceded
    redirect_to taxon_media_path(@taxon_concept, params.merge(:status => :moved_permanently).
        except(:controller, :action, :id, :taxon_id)) and return false if @taxon_concept.superceded_the_requested_id?
  end
end
