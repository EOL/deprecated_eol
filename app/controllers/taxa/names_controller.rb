class Taxa::NamesController < TaxaController

  before_filter :instantiate_taxon_concept

  def show
    includes = [
      { :published_hierarchy_entries => [ :name , :hierarchy, :hierarchies_content, :vetted ] },
      { :data_objects => { :toc_items => :info_items } },
      { :top_concept_images => :data_object },
      { :curator_activity_logs => :user },
      { :users_data_objects => { :data_object => :toc_items } }]
    selects = {
      :taxon_concepts => '*',
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :names => [ :string, :italicized, :canonical_form_id ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :hierarchies_content => [ :content_level, :image, :text, :child_image, :map, :youtube, :flash ],
      :vetted => :view_order,
      :data_objects => [ :id, :data_type_id, :vetted_id, :visibility_id, :published, :guid, :data_rating ],
      :table_of_contents => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name, :logo_cache_url, :tag_line ] }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(params[:taxon_id])
    @category = params['category']
    @category = params[:category]? params[:category] : "related_names"
    if @category == "related_names"
      @category_id = TocItem.related_names.id
    elsif @category == "synonyms"
      @category_id = TocItem.synonyms.id
    elsif @category == "common_names"
      @category_id = TocItem.common_names.id
    end


    @taxon_concept.current_user  = current_user
    @curator = @taxon_concept.current_user.can_curate?(@taxon_concept)
    get_content_variables(:ajax_update => true)
    
    if @content.nil?
      render :text => '[content missing]'
      return true
    else
      current_user.log_activity(:viewed_content_for_category_id, :value => @category_id, :taxon_concept_id => @taxon_concept.id)
    end
  end

private

end
