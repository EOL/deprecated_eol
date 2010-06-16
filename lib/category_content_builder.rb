# Responsible for building the non-default category content from the TOC, specifically for the following TOC items: Search
# the web, BHL, Common names, and Specialist projects
class CategoryContentBuilder
  
  # toc_item points to a TocItem object. 
  # options is a hash of content specific options
  # Mandatory keys include :vetted and :taxon_concept_id
  def content_for(toc_item, options)
    sub_name = toc_item.label.gsub(/\W/, '_').downcase

    # A list of current sub_names:
    #
    # biodiversity_heritage_library
    # common_names
    # biomedical_terms
    # search_the_web
    # specialist_projects

    content = {
      :category_name => toc_item.label,
      :content_type  => sub_name
    }

    if sub_name == "biodiversity_heritage_library"
      content.merge! biodiversity_heritage_library(options)
    elsif sub_name == "related_names"
      content.merge! related_names(options)
    elsif sub_name == "synonyms"
      content.merge! synonyms(options)
    elsif sub_name == "common_names"
      content.merge! common_names(options)
    elsif sub_name == "biomedical_terms"
      content.merge! biomedical_terms(options)
    elsif sub_name == "search_the_web"
      content.merge! search_the_web(options)
    elsif sub_name == "specialist_projects"
      content.merge! specialist_projects(options)
    elsif sub_name == "literature_references"
      content.merge! literature_references(options)
    elsif sub_name == "nucleotide_sequences"
      content.merge! nucleotide_sequences(options)
    else
      return nil # We don't handle this toc_item.
    end

    content
  end

# =============== The following are methods specific to content_by_category
private

  # TODO - change this (and the view) so that it's not reliant on hashes.  Paginate it.
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

    sorted_items = items.sort_by do|item|
      [item["publication_title"], item["item_year"], item["item_volume"], item["item_issue"], item["item_number"].to_i]
    end

    return {:items => sorted_items}

  end
  
  def related_names(options)
    return {:items => TaxonConcept.related_names(options[:taxon_concept_id])}
  end
  
  def synonyms(options)
    return {:items => TaxonConcept.synonyms(options[:taxon_concept_id])}
  end
  
  def common_names(options)
    unknown = Language.unknown.label
    names = EOL::CommonNameDisplay.find_by_taxon_concept_id(options[:taxon_concept_id])
    known_names = names.map {|n| n.language_label == unknown ? nil : n.name_id.to_i}.compact.uniq
    names = names.select {|n| (n.language_label != unknown) || (!known_names.include?(n.name_id.to_i))} 
    return {:items => names} 
  end

  def biomedical_terms(options)
    return {:item => HierarchyEntry.find_by_hierarchy_id_and_taxon_concept_id(Resource.ligercat.hierarchy.id, options[:taxon_concept_id])}
  end

  # This is all hard-coded in the view.
  def search_the_web(options)
    return {}
  end

  def specialist_projects(options)
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
