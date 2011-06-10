class Taxa::OverviewsController < TaxaController

  def show
    return if ! prepare_taxon_concept || @taxon_concept.nil?

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
      :users => [ :given_name, :family_name, :logo_cache_url, :credentials ] }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)

    toc_items = [TocItem.brief_summary, TocItem.comprehensive_description, TocItem.distribution]
    options = { :limit => 1 }
    @summary_text = @taxon_concept.text_objects_for_toc_items(toc_items, options)

    @media = @taxon_concept.media
    @feed_item = FeedItem.new(:feed_id => @taxon_concept.id, :feed_type => @taxon_concept.class.name)

    @assistive_section_header = I18n.t(:assistive_overview_header)

    current_user.log_activity(:viewed_taxon_concept_overview, :taxon_concept_id => @taxon_concept.id)

  end

end
