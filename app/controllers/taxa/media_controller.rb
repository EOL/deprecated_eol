class Taxa::MediaController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show

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
      :names => [ :string, :italicized, :canonical_form_id ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :hierarchies_content => [ :content_level, :image, :text, :child_image, :map, :youtube, :flash ],
      :vetted => :view_order,
      :data_objects => [ :id, :data_type_id, :vetted_id, :visibility_id, :published, :guid, :data_rating, :object_cache_url, :source_url ],
      :table_of_contents => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name ],
      :taxon_concept_exemplar_image => '*' }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)
    @exemplar_image = @taxon_concept.taxon_concept_exemplar_image.data_object unless @taxon_concept.taxon_concept_exemplar_image.blank?
    @media = @taxon_concept.media(:omit_type => true)

    @params_type = params['type'] || []
    @params_status = params['status'] || []

    @sort_by = params[:sort_by]

    unless @sort_by.blank?
      @media = DataObject.custom_filter(@media, @params_type, @params_status)
      @media = DataObject.custom_sort(@media, @sort_by, :omit_type => true) unless @sort_by == 'ranking'
    end

    @media = promote_exemplar(@media) if @exemplar_image && (@sort_by.blank? ||
      (@sort_by == 'ranking' && (@params_type.include?('all') || @params_type.include?('images'))))

    @sort_by ||= 'ranking'

    @media = @media.paginate(:page => params[:page] || 1, :per_page => $MAX_IMAGES_PER_PAGE)

    @assistive_section_header = I18n.t(:assistive_media_header)

    current_user.log_activity(:viewed_taxon_concept_media, :taxon_concept_id => @taxon_concept.id)
  end

  def set_as_exemplar
    TaxonConceptExemplarImage.set_exemplar(params[:taxon_id] || params[:id], params[:data_object_id])
    request.env['HTTP_REFERER'] ? (redirect_to :back) : (redirect_to taxon_media_path params[:taxon_concept_id])
  end

private

  def redirect_if_superceded
    redirect_to taxon_media_path(@taxon_concept, params.merge(:status => :moved_permanently).
        except(:controller, :action, :id, :taxon_id)) and return false if @taxon_concept.superceded_the_requested_id?
  end
end
