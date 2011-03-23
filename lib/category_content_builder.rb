# Responsible for building the non-default category content from the TOC (things like BHL and common names).
class CategoryContentBuilder

  def content_for(toc_item, options)
    sub_name = toc_item.label_as_method_name # TODO - i18n (this won't work without labels like the methods below)
    content = {
      :category_name => toc_item.label,
      :content_type  => sub_name
    }
    content.merge! self.send(sub_name, options)
    content
  end

  def can_handle?(toc_item)
    self.respond_to? toc_item.label_as_method_name
  end

  # TODO - Pagination
  def biodiversity_heritage_library(options)
    taxon_concept = options[:taxon_concept]
    name_ids = TaxonConceptName.find_all_by_taxon_concept_id_and_vern(taxon_concept, 0, :select => 'name_id').collect{|tcn| tcn.name_id}.uniq
    page_ids = PageName.find_all_by_name_id(name_ids, :select => 'item_page_id', :limit => 500).collect{|pn| pn.item_page_id}.uniq
    bhl_pages = ItemPage.core_relationships.find_all_by_id(page_ids)
    bhl_pages.delete_if{ |ip| ip.title_item.nil? || ip.title_item.publication_title.nil? }
    
    return {:items => ItemPage.sort_by_title_year(bhl_pages) }
  end

  def related_names(options)
    return {:items => TaxonConcept.related_names(options[:taxon_concept].id)}
  end

  def synonyms(options)
    return {:items => options[:taxon_concept].synonyms}
  end

  def common_names(options)
    unknown = Language.unknown.label # Just don't want to look it up every time.
    names = EOL::CommonNameDisplay.find_by_taxon_concept_id(options[:taxon_concept].id)
    names = names.select {|n| n.language_label != unknown} 
    return {:items => names} 
  end

  def content_summary(options)
    hash = options[:taxon_concept].published_hierarchy_entries.select{ |he| he.hierarchy.browsable? }
    return {:items => hash}
  end


  def biomedical_terms(options)
    return {:item => HierarchyEntry.find_by_hierarchy_id_and_taxon_concept_id(Resource.ligercat.hierarchy.id, options[:taxon_concept].id)}
  end

  # This is all hard-coded in the view.
  def search_the_web(options)
    return {}
  end

  def content_partners(options)
    tc_id = options[:taxon_concept].id
    tc = TaxonConcept.find(tc_id)
    outlinks = tc.outlinks
    sorted_outlinks = outlinks.sort_by { |ol| ol[:hierarchy_entry].hierarchy.label }
    return {:outlinks => sorted_outlinks}
  end

  def literature_references(options)
    tc_id = options[:taxon_concept].id
    return {:items => Ref.find_refs_for(tc_id)}
  end

  def nucleotide_sequences(options)
    tc_id = options[:taxon_concept].id
    entry = TaxonConcept.find_entry_in_hierarchy(tc_id, Hierarchy.ncbi.id)
    return {:hierarchy_entry => entry}
  end
end
