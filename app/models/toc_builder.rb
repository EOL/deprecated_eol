class TocBuilder

  # TODO - make a version of this for Hierarchy Entry:
  # TODO - MEDIUM PRIO - refactor this to take a taxon directly, rather than the id.
  def toc_for(taxon_concept_id, options = {})
    toc = DataObject.for_taxon(TaxonConcept.find(taxon_concept_id), :text, options)
    # Find out which toc items have unpublished content. Method published is accessible here  because
    # toc items are found by sql which has data_object fields. Every toc item corresponds to one data object
    # and is repeated potentially more than one time. They become unique after sort
    duplicates = {} #this duplicates seems super hacky, but the way the toc reuses columns from data objects seems super hacky as well
    i = 0
    toc = toc.map do |item|
      item.has_unpublished_content = true if item.published.to_i == 0
      #item.has_published_content = true if item.published.to_i == 1 && options[:agent_logged_in] && !item.data_supplier_agent.blank? && current_agent.id == item.data_supplier_agent.id
      item.has_published_content = false
      item.has_invisible_content = true if item.visibility_id.to_i == Visibility.invisible.id
      item.has_inappropriate_content = true if item.visibility_id.to_i == Visibility.inappropriate.id

      if duplicates[item.label]
        duplicates[item.label].each do |j|
          toc[j].has_unpublished_content = true if item.has_unpublished_content
          toc[j].has_published_content = true if item.has_published_content
          if item.has_invisible_content
            toc[j].has_invisible_content = true
          end
          toc[j].has_inappropriate_content = true if item.has_inappropriate_content
        end

        duplicates[item.label] << i
      else
        duplicates[item.label] = [i]
      end

      i += 1

      item
    end

    # Add specialist projects if there are entries in the mappings table for this name:
    if Mapping.specialist_projects_for?(taxon_concept_id)
      toc << TocItem.specialist_projects
    end

    # Add BHL content if there are corresponding page_names
    if PageName.page_names_for?(taxon_concept_id)
      toc << TocItem.bhl
    end

    # Add common names content if there Common Names:
    if TaxonConcept.common_names_for?(taxon_concept_id)
      toc << TocItem.common_names
    end

    vetted_only = (options[:user].blank? ? false : options[:user].vetted)
    if !vetted_only
      toc << TocItem.search_the_web 
    end
  
    return sort_toc(add_empty_parents(toc))
  end

  # Find all the parents and sort it's children
  def sort_toc(toc)
    parents = toc.select { |item| item.parent_id == 0 }.uniq.sort_by{ |item| item.view_order }
    new_toc = []
    # Now append the parent, then all its sorted children
    parents.each do |parent|
      new_toc << parent
      new_toc += toc.select { |item| item.parent_id == parent.id }.uniq.sort_by { |item| item.view_order }
    end
    return new_toc
  end
  
  # Iterate over the TOC finding elements that are children.
  # Done in two passes to avoid modifying an array during iteration
  def add_empty_parents(toc)
    children = []
    toc.each_with_index do |item, index|
      item.has_content = true
      if item.is_child?
        children << [index, item.parent_id]
      end
    end
    # So here we loop through those elements and add empty parents to the TOC:
    children.each do |child|
      toc[child[0], 0] = TocItem.find(child[1]) unless
        toc.any? {|i| i.id == child[1]} # This says, "unless the parent is already in the TOC"
    end
    return toc
  end

end