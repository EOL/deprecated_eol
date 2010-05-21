module ApiHelper
  
  def search_result_hash(options)
    
    last_page = (options[:results].total_entries/options[:per_page].to_f).ceil
    
    results = []
    for result in options[:results]
      result_hash = {}
      result_hash['id']           = result['id']
      result_hash['title']        = result['best_matched_scientific_name'].strip_italics
      result_hash['link']         = url_for(:controller => 'taxa', :action => 'show', :id => result['id'], :only_path => false)
      result_hash['content']      = result['scientific_name'].join(', ')+"\n\n"+result['common_name'].join(', ') if result['common_name']
      
      results << result_hash
    end
    
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
  
  
  def pages_json(details_hash, all_details = true)
    return_hash = {}
    return_hash['identifier'] = details_hash['id']
    return_hash['scientificName'] = details_hash['scientific_name']
    
    return_hash['vernacularNames'] = []
    for common_name in details_hash["common_names"]
      return_hash['vernacularNames'] << {
        'vernacularName' => common_name['name_string'],
        'language'       => common_name['iso_639_1']
      }
    end
    
    return_hash['taxonConcepts'] = []
    for entry in details_hash['curated_hierarchy_entries']
      entry_hash = {
        'identifier'      => entry.id,
        'scientificName'  => entry.name_object.string,
        'nameAccordingTo' => entry.hierarchy.label
      }
      entry_hash['sourceIdentfier'] = entry.identifier unless entry.identifier.blank?
      return_hash['taxonConcepts'] << entry_hash
    end
    
    return_hash['dataObjects'] = []
    for object in details_hash["data_objects"]
      return_hash['dataObjects'] << data_objects_json(object, all_details)
    end
    return return_hash
  end
  
  
  def data_objects_json(details_hash, all_details = true)
    return_hash = {}
    return_hash['identifier']             = details_hash["guid"]
    return_hash['dataType']               = details_hash["data_type"]
    return return_hash unless all_details == true
    
    return_hash['mimeType']               = details_hash["mime_type"]
    return_hash['created']                = details_hash["object_created_at"] unless details_hash["object_created_at"].blank?
    return_hash['modified']               = details_hash["updated_at"] unless details_hash["updated_at"].blank?
    return_hash['title']                  = details_hash["object_title"] unless details_hash["object_title"].blank?
    return_hash['language']               = details_hash["language"] unless details_hash["language"].blank?
    return_hash['license']                = details_hash["license"] unless details_hash["license"].blank?
    return_hash['rights']                 = details_hash["rights_statement"] unless details_hash["rights_statement"].blank?
    return_hash['rightsHolder']           = details_hash["rights_holder"] unless details_hash["rights_holder"].blank?
    return_hash['bibliographicCitation']  = details_hash["bibliographic_citation"] unless details_hash["bibliographic_citation"].blank?
    return_hash['source']                 = details_hash["source_url"] unless details_hash["source_url"].blank?
    return_hash['subject']                = details_hash["subject"] unless details_hash["subject"].blank?
    return_hash['description']            = details_hash["description"] unless details_hash["description"].blank?
    return_hash['mediaURL']               = details_hash["object_url"] unless details_hash["object_url"].blank?
    return_hash['eolMediaURL']            = DataObject.image_cache_path(details_hash["object_cache_url"], :large) unless details_hash["object_cache_url"].blank?
    return_hash['eolThumbnailURL']        = DataObject.image_cache_path(details_hash["object_cache_url"], :medium) unless details_hash["object_cache_url"].blank?
    return_hash['location']               = details_hash["location"] unless details_hash["location"].blank?
    
    unless details_hash['latitude']=="0" && details_hash['longitude']=="0" && details_hash['altitude']=="0"
      return_hash['latitude'] = details_hash['latitude'] unless details_hash['latitude']=="0"
      return_hash['longitude'] = details_hash['longitude'] unless details_hash['longitude']=="0"
      return_hash['altitude'] = details_hash['altitude'] unless details_hash['altitude']=="0"
    end
    
    return_hash['agents'] = []
    unless details_hash["agents"].blank?
      for agent in details_hash["agents"]
        return_hash['agents'] << {
          'full_name' => agent["full_name"],
          'homepage'  => agent["homepage"],
          'role'      => agent["role"].downcase
        }
      end
    end
    
    return_hash['references'] = []
    unless details_hash["refs"].nil?
      for ref in details_hash["refs"] 
        return_hash['references'] << ref["full_reference"]
      end
    end
    
    return return_hash
  end
  
  
  def hierarchy_entries_json()
    return_hash = {}
    
    return_hash['sourceIdentifier'] = @hierarchy_entry.identifier unless @hierarchy_entry.identifier.blank?
    return_hash['taxonID'] = @hierarchy_entry.id
    return_hash['parentNameUsageID'] = @hierarchy_entry.parent_id
    return_hash['taxonConceptID'] = @hierarchy_entry.taxon_concept_id
    return_hash['scientificName'] = @hierarchy_entry.name_object.string
    return_hash['taxonRank'] = @hierarchy_entry.rank.label.firstcap unless @hierarchy_entry.rank.nil?
    
    return_hash['nameAccordingTo'] = []
    for agent_role in @hierarchy_entry.agents_roles
      return_hash['nameAccordingTo'] << agent_role.agent.display_name
    end
    
    return_hash['vernacularNames'] = []
    for common_name in @common_names
      return_hash['vernacularNames'] << {
        'vernacularName' => common_name['name_string'],
        'language'       => common_name['language_code']
      }
    end
    
    return_hash['synonyms'] = []
    for synonym in @synonyms
      synonym_hash = {}
      synonym_hash['parentNameUsageID'] = @hierarchy_entry.id
      synonym_hash['scientificName'] = synonym['name_string']
      synonym_hash['taxonomicStatus'] = synonym['relation']
      return_hash['synonyms'] << synonym_hash
    end
    
    return_hash['ancestors'] = []
    for ancestor in @ancestors
      ancestor_hash = {}
      ancestor_hash['sourceIdentifier'] = ancestor['identifier'] unless ancestor['identifier'].blank?
      ancestor_hash['taxonID'] = ancestor['id']
      ancestor_hash['parentNameUsageID'] = ancestor['parent_id']
      ancestor_hash['taxonConceptID'] = ancestor['taxon_concept_id']
      ancestor_hash['scientificName'] = ancestor['name_string']
      ancestor_hash['taxonRank'] = ancestor['rank_label'] unless ancestor['rank_label'].blank?
      return_hash['ancestors'] << ancestor_hash
    end
    
    return_hash['children'] = []
    for child in @children
      child_hash = {}
      child_hash['sourceIdentifier'] = child['identifier'] unless child['identifier'].blank?
      child_hash['taxonID'] = child['id']
      child_hash['parentNameUsageID'] = child['parent_id']
      child_hash['taxonConceptID'] = child['taxon_concept_id']
      child_hash['scientificName'] = child['name_string']
      child_hash['taxonRank'] = child['rank_label'] unless child['rank_label'].blank?
      return_hash['children'] << child_hash
    end
    return return_hash
  end
end
