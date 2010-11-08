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

    tc_id = options[:taxon_concept_id]

    items = SpeciesSchemaModel.connection.execute(%Q{
      SELECT ti.id item_id, pt.title publication_title, pt.url publication_url,
             pt.details publication_details, ip.year item_year, ip.volume item_volume,
             ip.issue item_issue, ip.prefix item_prefix, ip.number item_number, ip.url item_url
      FROM taxon_concept_names tcn
        STRAIGHT_JOIN page_names pn ON (tcn.name_id = pn.name_id)
        JOIN item_pages ip ON (pn.item_page_id = ip.id)
        JOIN title_items ti ON (ip.title_item_id = ti.id)
        JOIN publication_titles pt ON (ti.publication_title_id = pt.id)
      WHERE tcn.taxon_concept_id = #{tc_id}
      LIMIT 0,1000
    }).all_hashes.uniq

    sorted_items = items.sort_by do |item|
      [item["publication_title"], item["item_year"], item["item_volume"], item["item_issue"], item["item_number"].to_i]
    end

    return {:items => sorted_items.map {|i| BhlItem.new(i) }}

  end

  def related_names(options)
    return {:items => TaxonConcept.related_names(options[:taxon_concept_id])}
  end

  def synonyms(options)
    return {:items => TaxonConcept.synonyms(options[:taxon_concept_id])}
  end

  def common_names(options)
    unknown = Language.unknown.label # Just don't want to look it up every time.
    names = EOL::CommonNameDisplay.find_by_taxon_concept_id(options[:taxon_concept_id])
    names = names.select {|n| n.language_label != unknown} 
    return {:items => names} 
  end

  def content_summary(options)
    hash = TaxonConcept.entry_stats(options[:taxon_concept_id])
    return {:items => hash}
  end


  def biomedical_terms(options)
    return {:item => HierarchyEntry.find_by_hierarchy_id_and_taxon_concept_id(Resource.ligercat.hierarchy.id, options[:taxon_concept_id])}
  end

  # This is all hard-coded in the view.
  def search_the_web(options)
    return {}
  end

  def content_partners(options)
    tc_id = options[:taxon_concept_id]
    tc = TaxonConcept.find(tc_id)
    outlinks = tc.outlinks
    sorted_outlinks = outlinks.sort_by { |ol| ol[:hierarchy_entry].hierarchy.label }
    return {:outlinks => sorted_outlinks}
  end

  def literature_references(options)
    tc_id = options[:taxon_concept_id]
    return {:items => Ref.find_refs_for(tc_id)}
  end

  def nucleotide_sequences(options)
    tc_id = options[:taxon_concept_id]
    entry = TaxonConcept.find_entry_in_hierarchy(tc_id, Hierarchy.ncbi.id)
    return {:hierarchy_entry => entry}
  end


end
