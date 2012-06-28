class Mobile::TaxaController < Mobile::MobileController

  # TODO: methods in lib/shared_taxa_controller.rb are duplicates of app/controllers/taxa_controller.rb this needs tidying up and core developers need to be on board with this approach to maintain.
  include SharedTaxaController

  before_filter :instantiate_taxon_concept

  #before_filter :redirect_if_superceded
  #before_filter :add_page_view_log_entry

  def show
    includes = [
      { :published_hierarchy_entries => [ { :name => :ranked_canonical_form } , :hierarchy, :vetted ] },
      { :data_objects => [ :toc_items,  :info_items, { :data_objects_hierarchy_entries => :hierarchy_entry },
        { :curated_data_objects_hierarchy_entries => :hierarchy_entry } ] },
      { :top_concept_images => { :data_object => [ :users_data_object,
        { :data_objects_hierarchy_entries => :hierarchy_entry },
        { :curated_data_objects_hierarchy_entries => :hierarchy_entry } ] } },
      { :curator_activity_logs => :user },
      { :users_data_objects => { :data_object => :toc_items } }]
    selects = {
      :taxon_concepts => '*',
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :names => [ :string, :italicized, :canonical_form_id, :ranked_canonical_form_id ],
      :canonical_forms => [ :string ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :vetted => :view_order,
      :data_objects => [ :id, :data_type_id, :data_subtype_id, :published, :guid, :data_rating, :language_id ],
      :table_of_contents => '*',
      :data_objects_hierarchy_entries => '*',
      :curated_data_objects_hierarchy_entries => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name, :logo_cache_url, :tag_line ] }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)
    @browsable_hierarchy_entries ||= @taxon_concept.published_hierarchy_entries.select{ |he| he.hierarchy.browsable? }
    @browsable_hierarchy_entries = [@selected_hierarchy_entry] if @browsable_hierarchy_entries.blank? # TODO: Check this - we are getting here with a hierarchy entry that has a hierarchy that is not browsable.
    @browsable_hierarchy_entries.compact!
    @hierarchies = @browsable_hierarchy_entries.collect{|he| he.hierarchy }.uniq
    toc_items = [TocItem.brief_summary, TocItem.comprehensive_description, TocItem.distribution]
    options = {:limit => 1, :language => current_language.iso_639_1}
    @summary_text = @taxon_concept.text_objects_for_toc_items(toc_items, options)

    if @selected_hierarchy_entry
      @recognized_by = recognized_by
    end

    @media = promote_exemplar_image(@taxon_concept.media({}, @selected_hierarchy_entry))
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @assistive_section_header = I18n.t(:assistive_overview_header)

    current_user.log_activity(:viewed_taxon_concept_overview, :taxon_concept_id => @taxon_concept.id)
  end

end

