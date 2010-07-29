xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response "xmlns" => "http://www.eol.org/transfer/content/1.0",
  "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/",
  "xmlns:dwc".to_sym => "http://rs.tdwg.org/dwc/terms/",
  "xmlns:dcterms".to_sym => "http://purl.org/dc/terms/",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
  "xsi:schemaLocation" => "http://www.eol.org/transfer/content/1.0 http://services.eol.org/schema/content_1_0.xsd" do                                                                                                               
  
  unless details_hash.blank?
    xml.taxonConcept do
      xml.taxonConceptID details_hash['id']
      xml.dwc :scientificName, details_hash['scientific_name']
      
      for common_name in details_hash["common_names"]
        xml.commonName common_name['name_string'], 'xml:lang'.to_sym => common_name['iso_639_1']
      end
      
      unless details_hash['curated_hierarchy_entries'].blank?
        xml.additionalInformation do
          for entry in details_hash['curated_hierarchy_entries']
            xml.taxon do
              xml.dc :identifier, entry.identifier unless entry.identifier.blank?
              xml.dwc :taxonID, entry.id
              xml.dwc :scientificName, entry.name_object.string
              xml.dwc :nameAccordingTo, entry.hierarchy.label
            end
          end
        end
      end
    end
    
    for object in details_hash["data_objects"]
      if data_object_details
        xml << render(:partial => 'data_object_1_0.xml.builder', :layout => false, :locals => { :object_hash => object, :taxon_concept_id => details_hash['id'], :minimal => false } )
      else
        xml << render(:partial => 'data_object_1_0.xml.builder', :layout => false, :locals => { :object_hash => object, :taxon_concept_id => details_hash['id'], :minimal => true } )
      end
    end
  end
end
