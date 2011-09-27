class Taxa::DetailsController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid
  before_filter :add_page_view_log_entry, :update_user_content_level

  # GET /pages/:taxon_id/details
  def index

    includes = [
      { :published_hierarchy_entries => [ :name , :hierarchy, :hierarchies_content, :vetted ] },
      { :data_objects => [ :translations, :data_object_translation, { :toc_items => :info_items }, { :data_objects_hierarchy_entries => :hierarchy_entry },
        { :curated_data_objects_hierarchy_entries => :hierarchy_entry }, :info_items, :users_data_object ] },
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
      :info_items => '*',
      :users_data_objects => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name, :logo_cache_url ] ,
      :taxon_concept_exemplar_image => '*' }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)
    @taxon_concept.current_user = current_user
    @details = @taxon_concept.details_for_toc_items(ContentTable.details.toc_items)
    @details.delete_if{ |d| d[:data_objects].blank? }
    
    @details_count_by_language = {}
    @details.each do |det|
      unless TocItem.exclude_from_details.include?(det[:toc_item])
        if det[:data_objects]
          det[:data_objects].each do |d|
            @details_count_by_language[d.language] ||= 0
            @details_count_by_language[d.language] += 1
            det[:data_objects].delete(d) unless d.language_id == current_user.language_id
          end
          # remove anything not in the current users language
          det[:data_objects].delete_if{ |d| d.language_id != current_user.language_id }
        end
      end
    end
    @details_count_by_language.delete_if{ |k,v| k == current_user.language }
    # some sections may be empty now that other languages have been removed
    @details.delete_if{ |d| d[:data_objects].blank? }
    
    toc_items_to_show = @details.blank? ? [] : @details.collect{|d| d[:toc_item]}
    exclude = TocItem.exclude_from_details
    toc_items_to_show.delete_if {|ti| exclude.include?(ti.label) }
    TocItem.preload_associations(toc_items_to_show, :info_items)
    @toc = TocBuilder.new.toc_for_toc_items(toc_items_to_show)
    @exemplar_image = @taxon_concept.exemplar_or_best_image_from_solr(@selected_hierarchy_entry)
    
    
    @assistive_section_header = I18n.t(:assistive_details_header)
    current_user.log_activity(:viewed_taxon_concept_details, :taxon_concept_id => @taxon_concept.id)
  end

private

  def redirect_if_superceded
    redirect_to taxon_details_path(@taxon_concept, params.merge(:status => :moved_permanently).
        except(:controller, :action, :id, :taxon_id)) and return false if @taxon_concept.superceded_the_requested_id?
  end

end
