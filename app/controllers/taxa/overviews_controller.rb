class Taxa::OverviewsController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    includes = [
      { :published_hierarchy_entries => [ { :name => :ranked_canonical_form } , :hierarchy, :hierarchies_content, :vetted ] },
      { :data_objects => [ :toc_items,  :info_items, { :data_objects_hierarchy_entries => :hierarchy_entry },
        { :curated_data_objects_hierarchy_entries => :hierarchy_entry } ] },
      { :curator_activity_logs => :user },
      { :users_data_objects => { :data_object => :toc_items } }]
    selects = {
      :taxon_concepts => '*',
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :names => [ :string, :italicized, :canonical_form_id, :ranked_canonical_form_id ],
      :canonical_forms => [ :string ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :hierarchies_content => [ :content_level, :image, :text, :child_image, :map, :youtube, :flash ],
      :vetted => :view_order,
      :data_objects => [ :id, :data_type_id, :data_subtype_id, :published, :guid, :data_rating, :language_id ],
      :table_of_contents => '*',
      :data_objects_hierarchy_entries => '*',
      :curated_data_objects_hierarchy_entries => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name, :logo_cache_url, :tag_line, :curator_level_id ] }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)
    @browsable_hierarchy_entries ||= @taxon_concept.published_hierarchy_entries.select{ |he| he.hierarchy.browsable? }
    @browsable_hierarchy_entries = [@selected_hierarchy_entry] if @browsable_hierarchy_entries.blank? # TODO: Check this - we are getting here with a hierarchy entry that has a hierarchy that is not browsable.
    @browsable_hierarchy_entries.compact!
    @hierarchies = @browsable_hierarchy_entries.collect{|he| he.hierarchy }.uniq
    toc_items = [TocItem.brief_summary, TocItem.comprehensive_description, TocItem.distribution]
    options = {:limit => 1, :language => current_user.language_abbr}
    @summary_text = @taxon_concept.text_objects_for_toc_items(toc_items, options)

    if @selected_hierarchy_entry
      @recognized_by = recognized_by
    end

    @media = promote_exemplar(@taxon_concept.images_from_solr(4, @selected_hierarchy_entry))
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @assistive_section_header = I18n.t(:assistive_overview_header)

    current_user.log_activity(:viewed_taxon_concept_overview, :taxon_concept_id => @taxon_concept.id)
  end

private

  def recognized_by
    @recognized_by = I18n.t(:recognized_by)
    if !@selected_hierarchy_entry.hierarchy.url.blank?
      @recognized_by << ' ' <<
        self.class.helpers.link_to(@selected_hierarchy_entry.hierarchy.label, @selected_hierarchy_entry.hierarchy.url)
    else
      @recognized_by << ' ' << @selected_hierarchy_entry.hierarchy.label
    end
  end

end
