class Taxa::DetailsController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid
  before_filter :add_page_view_log_entry, :update_user_content_level

  def index

    # map.connect 'pages/:taxon_id/entries/he_id/details',
    #              :controller => 'taxa',
    #              :action => 'hierarchy_entry_switch'

    if(params[:he_id])
      he = HierarchyEntry.find_by_id(params[:he_id])
      tc_id = he.taxon_concept_id
      @taxon_concept = TaxonConcept.find_by_id(tc_id)
    end  
    

    includes = [
      { :published_hierarchy_entries => [ :name , :hierarchy, :hierarchies_content, :vetted ] },
      { :data_objects => { :toc_items => :info_items } },
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
      :data_objects => [ :id, :data_type_id, :vetted_id, :visibility_id, :published, :guid, :data_rating, :object_cache_url ],
      :table_of_contents => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name, :logo_cache_url ] ,
      :taxon_concept_exemplar_image => '*' }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)

    @details = @taxon_concept.details_for_toc_items(ContentTable.details.toc_items)

    @toc = TocBuilder.new.toc_for_toc_items(@details.collect{|d| d[:toc_item]})

    @exemplar_image = @taxon_concept.taxon_concept_exemplar_image.data_object unless @taxon_concept.taxon_concept_exemplar_image.blank?

    @watch_collection = logged_in? ? current_user.watch_collection : nil

    @assistive_section_header = I18n.t(:assistive_details_header)

    dropdown_hierarchy_entry_id = params[:he_id] || ""
    @dropdown_hierarchy_entry = HierarchyEntry.find_by_id(dropdown_hierarchy_entry_id);

    current_user.log_activity(:viewed_taxon_concept_details, :taxon_concept_id => @taxon_concept.id)

  end

private

  def redirect_if_superceded
    redirect_to taxon_details_path(@taxon_concept, params.merge(:status => :moved_permanently).
        except(:controller, :action, :id, :taxon_id)) and return false if @taxon_concept.superceded_the_requested_id?
  end

end
