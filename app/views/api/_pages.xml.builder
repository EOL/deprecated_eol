xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response "xmlns" => "http://www.eol.org/transfer/content/0.3",
  "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/",
  "xmlns:dwc".to_sym => "http://rs.tdwg.org/dwc/dwcore/",
  "xmlns:dcterms".to_sym => "http://purl.org/dc/terms/",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
  "xsi:schemaLocation" => "http://www.eol.org/transfer/content/0.3 http://services.eol.org/schema/content_0_3.xsd" do                                                                                                               
  
  unless details_hash.blank?
    xml.taxon do
      xml.dc :identifier, details_hash['id']
      xml.dwc :ScientificName, details_hash['scientific_name']
      
      for common_name in details_hash["common_names"]
        xml.commonName common_name['name_string'], 'xml:lang'.to_sym => common_name['iso_639_1']
      end
      
      for object in details_hash["data_objects"]
        if data_object_details
          xml << render(:partial => 'data_object.xml.builder', :layout => false, :locals => { :object_hash => object } )
        else
          xml << render(:partial => 'data_object_minimal.xml.builder', :layout => false, :locals => { :object_hash => object } )
        end
      end
    end
  end
end
