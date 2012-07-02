class Mobile::Taxa::MediaController < Mobile::TaxaController

  def index
    includes = [
      { :published_hierarchy_entries => [ :name , :hierarchy, :vetted ] },
      { :data_objects => { :toc_items => :info_items } },
      { :top_concept_images => :data_object },
      { :curator_activity_logs => :user },
      { :users_data_objects => { :data_object => :toc_items } },
      { :taxon_concept_exemplar_image => :data_object }]
    selects = {
      :taxon_concepts => '*',
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :names => [ :string, :italicized, :canonical_form_id ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :vetted => :view_order,
      :data_objects => [ :id, :data_type_id, :data_subtype_id, :published, :guid, :data_rating, :object_cache_url, :source_url ],
      :table_of_contents => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name ],
      :taxon_concept_exemplar_image => '*' }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)
    @exemplar_image = @taxon_concept.taxon_concept_exemplar_image.data_object unless @taxon_concept.taxon_concept_exemplar_image.blank?

    @params_type = params['type'] || ['all']
    @params_status = params['status'] || []
    @sort_by = params[:sort_by]

    sort_order = [:visibility, :vetted, :rating, :date, :type] if @sort_by.blank? || @sort_by == 'status' #default
    sort_order = [:visibility, :rating, :vetted, :date, :type] if @sort_by == 'rating'
    sort_order = [:visibility, :date, :vetted, :rating, :type] if @sort_by == 'newest'

    @media = @taxon_concept.media(sort_order)

    @media = promote_exemplar_image(@media) if @exemplar_image && (@sort_by.blank? ||
      (@sort_by == 'status' && (@params_type.include?('all') || @params_type.include?('images'))))

    @sort_by ||= 'status'

    @media = @media.paginate(:page => params[:page] || 1, :per_page => $MAX_IMAGES_PER_PAGE)

    @watch_collection = logged_in? ? current_user.watch_collection : nil

    @assistive_section_header = I18n.t(:assistive_media_header)

    current_user.log_activity(:viewed_taxon_concept_media, :taxon_concept_id => @taxon_concept.id)
  end

end

