xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response "xmlns:dwc" => "http://rs.tdwg.org/dwc/terms/",
  "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do                                                                                                               
  
  xml.metadata do
    xml.dc :title, @hierarchy.label
    xml.dc :contributor, @hierarchy.agent.full_name
    xml.dc :dateSubmitted, @hierarchy.indexed_on.mysql_timestamp
    xml.dc :source, @hierarchy.url
  end
  
  unless @hierarchy.blank?
    for kingdom in @hierarchy_roots
      xml.dwc :Taxon do
        xml.dc :identifier, kingdom.identifier unless kingdom.identifier.blank?
        xml.dwc :taxonID, kingdom.id
        xml.dwc :parentNameUsageID, kingdom.parent_id
        xml.dwc :taxonConceptID, kingdom.taxon_concept_id
        xml.dwc :scientificName, kingdom.name.string.firstcap
        xml.dwc :taxonRank, kingdom.rank.label unless kingdom.rank_id == 0 || kingdom.rank.blank?
      end
    end
  end
end
