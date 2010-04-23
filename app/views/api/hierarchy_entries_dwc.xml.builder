xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.dwr :DarwinRecordSet,
    "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
    "xmlns:dcterms"       => "http://purl.org/dc/terms/",
    "xmlns:dwc"           => "http://rs.tdwg.org/dwc/terms/",
    "xmlns:dwr"           => "http://rs.tdwg.org/dwc/dwcrecord/",
    "xsi:schemaLocation"  => "http://rs.tdwg.org/dwc/dwcrecord/  http://rs.tdwg.org/dwc/xsd/tdwg_dwc_classes.xsd" do
  
  for ancestor in @ancestors
    xml.dwc :Taxon do
      xml.dwc :taxonID, ancestor['id']
      xml.dwc :parentNameUsageID, ancestor['parent_id']
      xml.dwc :taxonConceptID, ancestor['taxon_concept_id']
      xml.dwc :scientificName, ancestor['name_string']
      xml.dwc :taxonRank, ancestor['rank_label'] unless ancestor['rank_label'].blank?
    end
  end
  
  xml.dwc :Taxon do
    xml.dwc :taxonID, @hierarchy_entry.id
    xml.dwc :parentNameUsageID, @hierarchy_entry.parent_id
    xml.dwc :taxonConceptID, ancestor['taxon_concept_id']
    xml.dwc :scientificName, @hierarchy_entry.name_object.string
    xml.dwc :taxonRank, @hierarchy_entry.rank.label.firstcap unless @hierarchy_entry.rank.nil?
    for common_name in @common_names
      xml.dwc :vernacularName, common_name['name_string'], 'xml:lang'.to_sym => common_name['language_code']
    end
    for agent_role in @hierarchy_entry.agents_roles
      xml.dwc :nameAccordingTo, agent_role.agent.display_name
    end
  end
  
  for synonym in @synonyms
    xml.dwc :Taxon do
      xml.dwc :parentNameUsageID, @hierarchy_entry.id
      xml.dwc :scientificName, synonym['name_string']
      xml.dwc :taxonomicStatus, synonym['relation']
    end
  end
  
  for child in @children
    xml.dwc :Taxon do
      xml.dwc :taxonID, child['id']
      xml.dwc :parentNameUsageID, child['parent_id']
      xml.dwc :scientificName, child['name_string']
      xml.dwc :taxonRank, child['rank_label'] unless child['rank_label'].blank?
    end
  end
end
