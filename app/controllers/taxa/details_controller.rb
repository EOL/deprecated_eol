class Taxa::DetailsController < TaxaController

  layout 'v2/taxa'

  def show
    return if ! prepare_taxon_concept || @taxon_concept.nil?

    includes = [
      { :published_hierarchy_entries => [ :name , :hierarchy, :hierarchies_content, :vetted ] },
      { :data_objects => { :toc_items => :info_items } },
      { :last_curated_dates => :user },
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
      :last_curated_dates => '*',
      :users => [ :given_name, :family_name, :logo_cache_url ] }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)

    @details = @taxon_concept.details_for_toc_items(ContentTable.details.toc_items)

    @toc = TocBuilder.new.toc_for_toc_items(@details.collect{|d| d[:toc_item]})

    @assistive_section_header = I18n.t(:assistive_details_header)

    current_user.log_activity(:viewed_taxon_concept_details, :taxon_concept_id => @taxon_concept.id)

  end
end
