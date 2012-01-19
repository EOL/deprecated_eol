module ApiHelper
  
  def search_result_hash(options)
    results = []
    for result in options[:results]
      result_hash = {}
      result_hash['id']           = result['resource_id']
      result_hash['title']        = result['instance'].title.strip_italics
      result_hash['link']         = url_for(:controller => 'taxa', :action => 'show', :id => result['resource_id'], :only_path => false)
      result_hash['content']      = result['keyword'].join('; ')
      results << result_hash
    end
    
    last_page = (options[:results].total_entries/options[:per_page].to_f).ceil
    search_api_url = url_for(:controller => 'api', :action => 'search', :id => options[:search_term], :format => options[:format], :only_path => false);
    return_hash = {}
    return_hash['totalResults'] = options[:results].total_entries
    return_hash['startIndex']   = ((options[:page]) * options[:per_page]) - options[:per_page] + 1
    return_hash['itemsPerPage'] = options[:per_page]
    return_hash['results']      = results
    return_hash['first']        = "#{search_api_url}?page=1" if options[:page] <= last_page
    return_hash['previous']     = "#{search_api_url}?page=#{options[:page]-1}" if options[:page] > 1 && options[:page] <= last_page
    return_hash['self']         = "#{search_api_url}?page=#{options[:page]}" if options[:page] <= last_page
    return_hash['next']         = "#{search_api_url}?page=#{options[:page]+1}" if options[:page] < last_page
    return_hash['last']         = "#{search_api_url}?page=#{last_page}" if options[:page] <= last_page
    return return_hash
  end
  
  
  def pages_json(taxon_concept, data_objects, all_details = true)
    return_hash = {}
    return_hash['identifier'] = taxon_concept.id
    return_hash['scientificName'] = taxon_concept.entry.name.string
    
    return_hash['vernacularNames'] = []
    if params[:common_names]
      for tcn in taxon_concept.common_names
        lang = tcn.language ? tcn.language.iso_639_1 : ''
        common_name_hash = {
          'vernacularName' => tcn.name.string,
          'language'       => lang
        }
        preferred = (tcn.preferred == 1) ? true : nil
        common_name_hash['eol_preferred'] = preferred unless preferred.blank?
        return_hash['vernacularNames'] << common_name_hash
      end
    end
    
    return_hash['taxonConcepts'] = []
    for entry in taxon_concept.curated_hierarchy_entries
      entry_hash = {
        'identifier'      => entry.id,
        'scientificName'  => entry.name.string,
        'nameAccordingTo' => entry.hierarchy.label
      }
      entry_hash['sourceIdentfier'] = entry.identifier unless entry.identifier.blank?
      return_hash['taxonConcepts'] << entry_hash
    end
    
    return_hash['dataObjects'] = []
    for data_object in data_objects
      return_hash['dataObjects'] << data_objects_json(data_object, all_details)
    end
    return return_hash
  end
  
  def data_objects_json(data_object, all_details = true)
    return_hash = {}
    return_hash['identifier']             = data_object.guid
    return_hash['dataType']               = data_object.data_type.schema_value
    return return_hash unless all_details == true
    
    return_hash['mimeType']               = data_object.mime_type.label unless data_object.mime_type.blank?
    return_hash['created']                = data_object.object_created_at unless data_object.object_created_at.blank?
    return_hash['modified']               = data_object.object_modified_at unless data_object.object_modified_at.blank?
    return_hash['title']                  = data_object.object_title unless data_object.object_title.blank?
    return_hash['language']               = data_object.language.iso_639_1 unless data_object.language.blank?
    return_hash['license']                = data_object.license.source_url unless data_object.license.blank?
    return_hash['rights']                 = data_object.rights_statement unless data_object.rights_statement.blank?
    return_hash['rightsHolder']           = data_object.rights_holder unless data_object.rights_holder.blank?
    return_hash['bibliographicCitation']  = data_object.bibliographic_citation unless data_object.bibliographic_citation.blank?
    return_hash['source']                 = data_object.source_url unless data_object.source_url.blank?
    return_hash['subject']                = data_object.info_items[0].schema_value unless data_object.info_items.blank?
    return_hash['description']            = data_object.description unless data_object.description.blank?
    return_hash['mediaURL']               = data_object.object_url unless data_object.object_url.blank?
    return_hash['eolMediaURL']            = DataObject.image_cache_path(data_object.object_cache_url, :orig, $SINGLE_DOMAIN_CONTENT_SERVER) unless data_object.object_cache_url.blank?
    return_hash['eolThumbnailURL']        = DataObject.image_cache_path(data_object.object_cache_url, '98_68', $SINGLE_DOMAIN_CONTENT_SERVER) unless data_object.object_cache_url.blank?
    return_hash['location']               = data_object.location unless data_object.location.blank?
    
    unless data_object.latitude == 0 && data_object.longitude == 0 && data_object.altitude == 0
      return_hash['latitude'] = data_object.latitude unless data_object.latitude == 0
      return_hash['longitude'] = data_object.longitude unless data_object.longitude == 0
      return_hash['altitude'] = data_object.altitude unless data_object.altitude == 0
    end
    
    return_hash['agents'] = []
    for ado in data_object.agents_data_objects
      if ado.agent
        return_hash['agents'] << {
          'full_name' => ado.agent.full_name,
          'homepage'  => ado.agent.homepage,
          'role'      => ado.agent_role.label.downcase
        }
      end
    end
    
    return_hash['references'] = []
    data_object.published_refs.each do |r|
      return_hash['references'] << r.full_reference
    end
    return_hash['vettedStatus'] = data_object.association_with_best_vetted_status.vetted.label unless data_object.association_with_best_vetted_status.vetted.blank?
    return_hash['dataRating'] =  data_object.data_rating
    
    return return_hash
  end
  
  
  def hierarchy_entries_json()
    return_hash = {}
    
    return_hash['sourceIdentifier'] = @hierarchy_entry.identifier unless @hierarchy_entry.identifier.blank?
    return_hash['taxonID'] = @hierarchy_entry.id
    return_hash['parentNameUsageID'] = @hierarchy_entry.parent_id
    return_hash['taxonConceptID'] = @hierarchy_entry.taxon_concept_id
    return_hash['scientificName'] = @hierarchy_entry.name.string
    return_hash['taxonRank'] = @hierarchy_entry.rank.label.firstcap unless @hierarchy_entry.rank.nil?
    
    stats = @hierarchy_entry.hierarchy_entry_stat
    return_hash['total_descendants'] = stats.total_children
    return_hash['total_trusted_text'] = stats.all_text_trusted
    return_hash['total_unreviewed_text'] = stats.all_text_untrusted
    return_hash['total_descendants_with_text'] = stats.have_text
    return_hash['total_trusted_images'] = stats.all_image_trusted
    return_hash['total_unreviewed_images'] = stats.all_image_untrusted
    return_hash['total_descendants_with_images'] = stats.have_images
    
    return_hash['nameAccordingTo'] = []
    for agent_role in @hierarchy_entry.agents_roles
      return_hash['nameAccordingTo'] << agent_role.agent.full_name
    end
    
    return_hash['vernacularNames'] = []
    if @include_common_names
      for common_name in @hierarchy_entry.common_names
        return_hash['vernacularNames'] << {
          'vernacularName' => common_name.name.string.firstcap,
          'language'       => common_name.language ? common_name.language.iso_639_1 : ''
        }
      end
    end
    
    return_hash['synonyms'] = []
    if @include_synonyms
      for synonym in @hierarchy_entry.scientific_synonyms
        synonym_hash = {}
        synonym_hash['parentNameUsageID'] = @hierarchy_entry.id
        synonym_hash['scientificName'] = synonym.name.string.firstcap
        synonym_hash['taxonomicStatus'] = synonym.synonym_relation.label rescue ''
        return_hash['synonyms'] << synonym_hash
      end
    end
    
    return_hash['ancestors'] = []
    for ancestor in @ancestors
      ancestor_hash = {}
      ancestor_hash['sourceIdentifier'] = ancestor.identifier unless ancestor.identifier.blank?
      ancestor_hash['taxonID'] = ancestor.id
      ancestor_hash['parentNameUsageID'] = ancestor.parent_id
      ancestor_hash['taxonConceptID'] = ancestor.taxon_concept_id
      ancestor_hash['scientificName'] = ancestor.name.string.firstcap
      ancestor_hash['taxonRank'] = ancestor.rank.label unless ancestor.rank_id == 0 || ancestor.rank.blank?
      return_hash['ancestors'] << ancestor_hash
    end
    
    return_hash['children'] = []
    for child in @children
      child_hash = {}
      child_hash['sourceIdentifier'] = child.identifier unless child.identifier.blank?
      child_hash['taxonID'] = child.id
      child_hash['parentNameUsageID'] = child.parent_id
      child_hash['taxonConceptID'] = child.taxon_concept_id
      child_hash['scientificName'] = child.name.string.firstcap
      child_hash['taxonRank'] = child.rank.label unless child.rank_id == 0 || child.rank.blank?
      return_hash['children'] << child_hash
    end
    return return_hash
  end
  
  def eol_providers_json
    return_hash = []
    for h in @hierarchies
      return_hash << {'id' => h.id, 'label' => h.label}
    end
    return return_hash
  end
  
  def search_by_providers_json
    return_hash = []
    for r in @results
      return_hash << {'eol_page_id' => r.taxon_concept_id}
    end
    return return_hash
  end
  
  def hierarchies_json
    return_hash = {}
    return_hash['title'] = @hierarchy.label
    return_hash['contributor'] = @hierarchy.agent.full_name
    return_hash['dateSubmitted'] = @hierarchy.indexed_on.mysql_timestamp
    return_hash['source'] = @hierarchy.url
    
    return_hash['roots'] = []
    for root in @hierarchy_roots
      root_hash = {}
      root_hash['sourceIdentifier'] = root.identifier unless root.identifier.blank?
      root_hash['taxonID'] = root.id
      root_hash['parentNameUsageID'] = root.parent_id
      root_hash['taxonConceptID'] = root.taxon_concept_id
      root_hash['scientificName'] = root.name.string.firstcap
      root_hash['taxonRank'] = root.rank.label unless root.rank_id == 0 || root.rank.blank?
      return_hash['roots'] << root_hash
    end
    return return_hash
  end
  
  def collections_json
    return_hash = {}
    return_hash['name'] = @collection.name
    return_hash['description'] = @collection.description
    return_hash['logo_url'] = @collection.logo_cache_url.blank? ? nil : @collection.logo_url
    return_hash['created'] = @collection.created_at
    return_hash['modified'] = @collection.updated_at
    return_hash['total_items'] = @collection_results.total_entries
    
    return_hash['item_types'] = []
    ['TaxonConcept', 'Text', 'Video', 'Image', 'Sound', 'Community', 'User', 'Collection'].each do |facet|
      return_hash['item_types'] << { 'item_type' => facet, 'item_count' => @facet_counts[facet] || 0 }
    end
    
    return_hash['collection_items'] = []
    @collection_results.each do |r|
      ci = r['instance']
      item_hash = {
        'name' => r['title'],
        'object_type' => ci.object_type,
        'object_id' => ci.object_id,
        'title' => ci.name,
        'created' => ci.created_at,
        'updated' => ci.updated_at,
        'annotation' => ci.annotation,
        'sort_field' => ci.sort_field
      }
      case ci.object_type
      when 'TaxonConcept'
        item_hash['richness_score'] = r['richness_score']
      when 'DataObject'
        item_hash['data_rating'] = r['data_rating']
        item_hash['object_guid'] = ci.object.guid
        item_hash['object_type'] = ci.object.data_type.simple_type
        if ci.object.is_image?
          item_hash['source'] = ci.object.thumb_or_object(:orig)
        end
      end
      return_hash['collection_items'] << item_hash
    end
    return return_hash
  end
  
end
