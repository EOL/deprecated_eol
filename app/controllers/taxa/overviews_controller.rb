class Taxa::OverviewsController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def show
    @browsable_hierarchy_entries ||= @taxon_concept.published_hierarchy_entries.select{ |he| he.hierarchy.browsable? }
    @browsable_hierarchy_entries = [@selected_hierarchy_entry] if @browsable_hierarchy_entries.blank? # TODO: Check this - we are getting here with a hierarchy entry that has a hierarchy that is not browsable.
    @browsable_hierarchy_entries.compact!
    @hierarchies = @browsable_hierarchy_entries.collect{|he| he.hierarchy }.uniq
    
    @summary_text = @taxon_concept.overview_text_for_user(current_user)
    
    @media = promote_exemplar(@taxon_concept.images_from_solr(4, @selected_hierarchy_entry, true))
    DataObject.preload_associations(@media, :translations , :conditions => "data_object_translations.language_id=#{current_user.language_id}")
    DataObject.preload_associations(@media, 
      [ :users_data_object,
        { :agents_data_objects => [ { :agent => :user }, :agent_role ] },
        { :data_objects_hierarchy_entries => [ { :hierarchy_entry => [ { :name => :canonical_form }, :taxon_concept, :vetted, :visibility,
          { :hierarchy => { :resource => :content_partner } } ] }, :vetted, :visibility ] },
        { :curated_data_objects_hierarchy_entries => { :hierarchy_entry => [ :name, :taxon_concept, :vetted, :visibility ] } } ] )
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @assistive_section_header = I18n.t(:assistive_overview_header)
    @rel_canonical_href = @selected_hierarchy_entry ?
      taxon_hierarchy_entry_overview_url(@taxon_concept, @selected_hierarchy_entry) :
      taxon_overview_url(@taxon_concept)
    current_user.log_activity(:viewed_taxon_concept_overview, :taxon_concept_id => @taxon_concept.id)
  end

end
