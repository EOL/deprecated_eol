class Mobile::Taxa::DetailsController < Mobile::TaxaController

  def index
    includes = [
      { :published_hierarchy_entries => [ :name , :hierarchy, :hierarchies_content, :vetted ] },
      { :data_objects => [ :translations, :data_object_translation, { :toc_items => :info_items }, { :data_objects_hierarchy_entries => :hierarchy_entry },
        { :curated_data_objects_hierarchy_entries => :hierarchy_entry } ] },
      { :top_concept_images => { :data_object => [
        { :data_objects_hierarchy_entries => :hierarchy_entry },
        { :curated_data_objects_hierarchy_entries => :hierarchy_entry } ] } },
      { :curator_activity_logs => :user },
      { :users_data_objects => [ { :data_object => :toc_items } ] },
      { :taxon_concept_exemplar_image => :data_object }]
    selects = {
      :taxon_concepts => '*',
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :names => [ :string, :italicized, :canonical_form_id, :ranked_canonical_form_id ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :hierarchies_content => [ :content_level, :image, :text, :child_image, :map, :youtube, :flash ],
      :vetted => :view_order,
      :data_objects => [ :id, :data_type_id, :data_subtype_id, :published, :guid, :data_rating, :object_cache_url, :language_id ],
      :data_objects_hierarchy_entries => '*',
      :curated_data_objects_hierarchy_entries => '*',
      :data_object_translations => '*',
      :table_of_contents => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name, :logo_cache_url ] ,
      :taxon_concept_exemplar_image => '*' }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)
    @taxon_concept.current_user = current_user
    @details = @taxon_concept.details_for_toc_items(ContentTable.details.toc_items, :language => current_user.language_abbr)

    toc_items_to_show = @details.blank? ? [] : @details.collect{|d| d[:toc_item]}

    # toc_items to exclude in Details tab
    temp = []
    # Education:
    temp = temp | ["Education", "Education Links", "Education Resources", "High School Lab Series"]
    # Physical Description:
    temp = temp | ["Morphology", "Size", "Diagnostic Description", "Look Alikes", "Development", "Identification Resources"]
    # Molecular Biology and Genetics:
    temp = temp | ["Genetics", "Nucleotide Sequences", "Barcode", "Genome", "Molecular Biology"]
    # References and More Information:
    temp = temp | ["Content Partners", "Literature References", "Bibliographies", "Bibliography", "Commentary", "On the Web", "Biodiversity Heritage Library", "Comments", "Search the Web", "Education Resources", "Biomedical Terms"]
    # Names and Taxonomy:
    temp = temp | ["Related Names", "Synonyms", "Common Names"]
    # Page Statistics:
    temp = temp | ["Content Summary"]
    # exclude selected toc_items
    toc_items_to_show.delete_if {|ti| temp.include?(ti.label)}

    @toc = []

    @exemplar_image = @taxon_concept.exemplar_or_best_image_from_solr

    @watch_collection = logged_in? ? current_user.watch_collection : nil

    @assistive_section_header = I18n.t(:assistive_details_header)

    current_user.log_activity(:viewed_taxon_concept_details, :taxon_concept_id => @taxon_concept.id)
  end

end
