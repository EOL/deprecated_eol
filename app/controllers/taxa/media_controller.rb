class Taxa::MediaController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid
  before_filter :add_page_view_log_entry, :update_user_content_level

  def index

    includes = [
      { :published_hierarchy_entries => [ :name , :hierarchy, :hierarchies_content, :vetted ] },
      { :data_objects => { :toc_items => :info_items } },
      { :top_concept_images => :data_object },
      { :curator_activity_logs => :user },
      { :users_data_objects => { :data_object => :toc_items } },
      { :taxon_concept_exemplar_image => :data_object }]
    selects = {
      :taxon_concepts => '*',
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :names => [ :string, :italicized, :canonical_form_id, :ranked_canonical_form_id ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :hierarchies_content => [ :content_level, :image, :text, :child_image, :map, :youtube, :flash ],
      :vetted => :view_order,
      :data_objects => [ :id, :data_type_id, :vetted_id, :visibility_id, :published, :guid, :data_rating, :object_cache_url, :source_url, :object_title, :description ],
      :table_of_contents => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name ],
      :taxon_concept_exemplar_image => '*' }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)
    @exemplar_image = @taxon_concept.taxon_concept_exemplar_image.data_object unless @taxon_concept.taxon_concept_exemplar_image.blank?
    @exemplar_image ||= @taxon_concept.best_image

    @params_type = params['type'] || ['all']
    @params_status = params['status'] || []
    @sort_by = params[:sort_by]

    sort_order = [:visibility, :vetted, :rating, :date, :type] if @sort_by.blank? || @sort_by == 'status' #default
    sort_order = [:visibility, :rating, :vetted, :date, :type] if @sort_by == 'rating'
    sort_order = [:visibility, :date, :vetted, :rating, :type] if @sort_by == 'newest'

    @media = @taxon_concept.media(sort_order, @dropdown_hierarchy_entry)
    @media = DataObject.custom_filter(@media, @params_type, @params_status) unless @params_type.blank? && @params_status.blank?
    @media = promote_exemplar(@media) if @exemplar_image && (@sort_by.blank? ||
      (@sort_by == 'status' && (@params_type.include?('all') || @params_type.include?('images'))))
    @sort_by ||= 'status'
    @media_total = @media.count
    @media = @media.paginate(:page => params[:page] || 1, :per_page => $MAX_IMAGES_PER_PAGE)
    @current_user_ratings = logged_in? ? current_user.rating_for_object_guids(@media.collect{ |m| m.guid }) : {}

    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @assistive_section_header = I18n.t(:assistive_media_header)
    current_user.log_activity(:viewed_taxon_concept_media, :taxon_concept_id => @taxon_concept.id)
  end

  def set_as_exemplar
    taxon_concept_id = params[:taxon_id] || params[:taxon_concept_exemplar_image][:taxon_concept_id]
    data_object_id = params[:taxon_concept_exemplar_image][:data_object_id]
    unless taxon_concept_id.blank? || data_object_id.blank?
      TaxonConceptExemplarImage.set_exemplar(taxon_concept_id, data_object_id)
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
