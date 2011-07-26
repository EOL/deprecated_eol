class Taxa::OverviewsController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    includes = [
      { :published_hierarchy_entries => [ { :name => :ranked_canonical_form } , :hierarchy, :hierarchies_content, :vetted ] },
      { :data_objects => [ :toc_items,  :info_items ] },
      { :top_concept_images => :data_object },
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
      :data_objects => [ :id, :data_type_id, :vetted_id, :visibility_id, :published, :guid, :data_rating, :language_id ],
      :table_of_contents => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name, :logo_cache_url, :tag_line ] }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)
    @hierarchies = @taxon_concept.published_hierarchy_entries.collect{|he| he.hierarchy if he.hierarchy.browsable? }.uniq
    toc_items = [TocItem.brief_summary, TocItem.comprehensive_description, TocItem.distribution]
    options = {:limit => 1, :language => current_user.language_abbr}
    @summary_text = @taxon_concept.text_objects_for_toc_items(toc_items, options)

    if @dropdown_hierarchy_entry
      @recognized_by = recognized_by
    end

    @media = promote_exemplar(@taxon_concept.media({}, @dropdown_hierarchy))
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @assistive_section_header = I18n.t(:assistive_overview_header)

    # add the user's hierarchy in case the current concept is it
    # we'll need to default the list to the user's hierarchy no matter what
    # @hierarchies_to_offer << @session_hierarchy
    # @hierarchies_to_offer = @hierarchies_to_offer.uniq.sort_by{|h| h.form_label}
    current_user.log_activity(:viewed_taxon_concept_overview, :taxon_concept_id => @taxon_concept.id)
  end

private

  def redirect_if_superceded
    redirect_to taxon_overview_path(@taxon_concept, params.merge(:status => :moved_permanently).
        except(:controller, :action, :id, :taxon_id)) and return false if @taxon_concept.superceded_the_requested_id?
  end
  
  def recognized_by
    @recognized_by = I18n.t(:recognized_by)
    if !@dropdown_hierarchy_entry.hierarchy.url.blank?
      @recognized_by << ' ' << self.class.helpers.link_to( @dropdown_hierarchy_entry.hierarchy.label , @dropdown_hierarchy_entry.hierarchy.url)
    else
      @recognized_by << ' ' << @dropdown_hierarchy_entry.hierarchy.label
    end
  end

end
