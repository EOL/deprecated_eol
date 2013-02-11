# This represents the details (text objects) of a taxon concept, providing a minimal interface to only the aspects you
# might need to display one.
#
# NOTE that this class uses a plural for a single instance; this is a fairly standard practice for these types of 
# Presenter objects, when appropriate.
class TaxonDetails < TaxonUserClassificationFilter

  def count_by_language
    return @details_count_by_language if defined? @details_count_by_language 
    @details_count_by_language = {}
    details_in_all_other_languages.each do |obj|
      obj.language = obj.language.representative_language
      next unless Language.approved_languages.include?(obj.language)
      @details_count_by_language[obj.language] ||= 0
      @details_count_by_language[obj.language] += 1
    end
    @details_count_by_language
  end

  def thumb?
    image && thumb
  end

  def thumb
    @thumb ||= image.thumb_or_object('260_190')
  end

  def details(options = {})
    @details ||= DataObject.sort_by_rating(details_text_for_user, taxon_concept)
    options[:include_toc_item] ?
      @details.select { |d| !d.toc_items.include?(options[:include_toc_item]) } :
      @details
  end

  def toc_items?
    toc_roots
  end

  # Passes back the child and the content for that child.
  def each_toc_item(&block)
    toc_roots.each do |toc_item|
      yield(toc_item, details_cache(toc_item))
    end
  end

  def toc_items_under?(under)
    toc_nest_under(under)
  end

  def each_nested_toc_item(under)
    toc_nest_under(under).each do |toc_item|
      yield(toc_item, details_cache(toc_item))
    end
  end

private

  def details_cache(item)
    @details_cache[item] ||= details(:include_toc_item => item)
  end

  def toc_nest_under(under)
    @toc_nest[under] ||= toc(:under => under)
  end

  def toc_roots
    @toc_roots ||= toc.dup.delete_if(&:is_child?)
  end

  def details_in_all_other_languages
    DataObject.preload_associations(
      taxon_concept.text_for_user(user,
        :language_ids_to_ignore => user.language.all_ids << 0,
        :allow_nil_languages => false,
        :preload_select => { :data_objects => [ :id, :guid, :language_id, :data_type_id, :created_at, :rights_holder ] },
        :skip_preload => true,
        :toc_ids_to_ignore => TocItem.exclude_from_details.map { |toc_item| toc_item.id }
      ),
      :language
    )
  end

  # TODO - there are three other methods related to this one, but I don't want to move them yet.
  def details_text_for_user(only_one = false)
    text_objects = taxon_concept.text_for_user(user,
      :language_ids => [ user.language_id ],
      :filter_by_subtype => true,
      :allow_nil_languages => user.default_language?,
      :toc_ids_to_ignore => TocItem.exclude_from_details.collect { |toc_item| toc_item.id },
      :per_page => (only_one ? 1 : 600) # NOTE - artificial limit of text objects here to increase the default 30
    )
    
    # now preload info needed for display details metadata
    unless only_one
      selects = {
        :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
        :hierarchies => [ :id, :agent_id, :browsable, :outlink_uri, :label ],
        :data_objects_hierarchy_entries => '*',
        :curated_data_objects_hierarchy_entries => '*',
        :data_object_translations => '*',
        :table_of_contents => '*',
        :info_items => '*',
        :toc_items => '*',
        :translated_table_of_contents => '*',
        :users_data_objects => '*',
        :resources => '*',
        :content_partners => 'id, user_id, full_name, display_name, homepage, public',
        :refs => '*',
        :ref_identifiers => '*',
        :comments => 'id, parent_id',
        :licenses => '*',
        :users_data_objects_ratings => '*' }
      DataObject.preload_associations(text_objects, [ :users_data_objects_ratings, :comments, :license,
        { :published_refs => :ref_identifiers }, :translations, :data_object_translation, { :toc_items => :info_items },
        { :data_objects_hierarchy_entries => [ { :hierarchy_entry => { :hierarchy => { :resource => :content_partner } } },
          :vetted, :visibility ] },
        { :curated_data_objects_hierarchy_entries => :hierarchy_entry }, :users_data_object,
        { :toc_items => [ :translations ] } ], :select => selects)
    end
    text_objects
  end
  
end
