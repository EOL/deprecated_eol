class TocBuilder

  def toc_for(taxon_concept, options = {})
    toc = get_normal_text_toc_entries_for_taxon(taxon_concept, options)
    add_special_toc_entries_to_toc_based_on_tc_id(toc, taxon_concept, options)
    return sort_toc(add_empty_parents(toc))
  end

private

  def get_normal_text_toc_entries_for_taxon(taxon_concept, options)
    text_toc_items = DataObject.for_taxon(taxon_concept, :text, options)
    return convert_toc_items_to_toc_entries(text_toc_items)
  end

  # Find all the parents and sort it's children.  Yes, it's true that the view_order does NOT account for parents.
  def sort_toc(toc)
    new_toc = []
    parents = toc.select { |item| item.is_parent? }.uniq.sort
    parents.each do |parent|
      new_toc << parent
      new_toc += toc.select { |item| item.parent_id == parent.category_id }.uniq.sort
    end
    return new_toc
  end
  
  # Iterate over the TOC finding elements that are children.
  # Done in two passes to avoid modifying an array during iteration
  def add_empty_parents(toc)
    children = []
    toc.each_with_index do |item, index|
      if item.is_child?
        children << {:where => index, :parent_id => item.parent_id}
      end
    end
    # So here we loop through those elements and add empty parents to the TOC:
    children.each do |child|
      toc[child[:where], 0] = TocEntry.new(TocItem.find(child[:parent_id]), :has_content => false) unless
        toc.any? {|i| i.category_id == child[:parent_id]} # This says, "unless the parent is already in the TOC"
    end
    return toc
  end

  # Find out which toc items have unpublished content. Method published is accessible here because
  # toc items are found by sql which has data_object fields. Every toc item corresponds to one data object
  # and is repeated potentially more than one time. They become unique after sort
  def convert_toc_items_to_toc_entries(toc_items)
    toc = [] # Our new toc starts empty.
    toc_items.each do |toc_item|

      # If this toc_item is already in the toc, find it:
      toc_entry_index = index_of_toc_entry_by_toc_item_id_in(toc_item.id, toc)

      if toc_entry_index.nil? # It's not there, add it:
        toc << TocEntry.new(toc_item)
      else # There already was one:
        toc[toc_entry_index].merge_attribues_with(toc_item)
      end

    end

    return toc

  end

  def index_of_toc_entry_by_toc_item_id_in(item_id, toc)
    matches = toc.select {|te| te.category_id == item_id}
    return nil if matches.blank?
    return toc.index(matches.first)
  end

  def add_special_toc_entries_to_toc_based_on_tc_id(toc, taxon_concept, options)
    
    # Add specialist projects if there are entries in the mappings table for this name:
    if Mapping.specialist_projects_for?(taxon_concept.id)
      toc << TocEntry.new(TocItem.specialist_projects)
    end
    
    # Add BHL content if there are corresponding page_names
    if PageName.page_names_for?(taxon_concept.id)
      toc << TocEntry.new(TocItem.bhl)
    end
    
    if TaxonConcept.related_names_for?(taxon_concept.id)
      toc << TocEntry.new(TocItem.related_names)
    end
    
    if TaxonConcept.synonyms_for?(taxon_concept.id)
      toc << TocEntry.new(TocItem.synonyms)
    end
    
    # Add common names content if there Common Names:
    if TaxonConcept.common_names_for?(taxon_concept.id) || (!options[:user].nil? && options[:user].can_curate?(taxon_concept))
      toc << TocEntry.new(TocItem.common_names)
    end
    
    # Add Medical Concepts if there is a LigerCat tag cloud available:
    if !Collection.ligercat.nil? && Mapping.specialist_projects_for?(taxon_concept.id, :collection_id => Collection.ligercat.id)
      toc << TocEntry.new(TocItem.biomedical_terms)
    end
    
    # Add Literature references entry if references exists
    if Ref.literature_references_for?(taxon_concept.id)
      toc << TocEntry.new(TocItem.literature_references)
    end
    
    # Add Nucleotide Sequences entry if NCBI has a page for this concept
    if entry = TaxonConcept.find_entry_in_hierarchy(taxon_concept.id, Hierarchy.ncbi.id)
      toc << TocEntry.new(TocItem.nucleotide_sequences) if entry.identifier != ''
    end
    
    if user_allows_unvetted_items(options)
      toc << TocEntry.new(TocItem.search_the_web)
    end

    if Ref.literature_references_for?(taxon_concept.id)
      toc << TocEntry.new(TocItem.literature_references)
    end

  end

  def user_allows_unvetted_items(options = {})
    return(false) if options[:user].blank?
    return true if options[:user] and not options[:user].vetted
  end
  
end
