class Taxa::MapsController < TaxaController
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
      :names => [ :string, :italicized, :canonical_form_id, :ranked_canonical_form_id ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :hierarchies_content => [ :content_level, :image, :text, :child_image, :map, :youtube, :flash ],
      :vetted => :view_order,
      :data_objects => [ :id, :data_type_id, :vetted_id, :visibility_id, :published, :guid, :data_rating ],
      :table_of_contents => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name, :logo_cache_url, :tag_line ] }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(params[:taxon_id])
    @taxon_concept.current_user  = current_user
    @curator = @taxon_concept.current_user.can_curate?(@taxon_concept)
    @dropdown_hierarchy_entry_id = params[:hierarchy_entry_id]
    @dropdown_hierarchy_entry = HierarchyEntry.find_by_id(@dropdown_hierarchy_entry_id) rescue nil
    @hierarchy_entries_to_offer = @taxon_concept.published_hierarchy_entries
    @assistive_section_header = I18n.t(:assistive_maps_header)
    current_user.log_activity(:viewed_taxon_concept_maps, :taxon_concept_id => @taxon_concept.id)
  end

private

end
