# http://services.eol.org/schema/documentation_0_2.pdf
# http://localhost:3000/pages/25/best_images.xml


# <?xml version="1.0" encoding="utf-8" ?>
# <response
#     xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
#     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
#     xsi:schemaLocation="http://www.eol.org/transfer/content/0.2 http://services.eol.org/schema/content_0_2.xsd">


xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response "xmlns" => "http://www.eol.org/transfer/content/0.2", "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/", "xmlns:dwc".to_sym => "http://rs.tdwg.org/dwc/dwcore/", "xmlns:dcterms".to_sym => "http://purl.org/dc/terms/", "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xsi:schemaLocation" => "http://www.eol.org/transfer/content/0.2 http://services.eol.org/schema/content_0_2.xsd" do                                                                                                               

  xml.taxon do
    xml.dc :identifier, @best_images_taxon_to_xml["identifier"]
    xml.dwc :Kingdom, @best_images_taxon_to_xml["kingdom"] if @best_images_taxon_to_xml["kingdom"]
    xml.dwc :Phylum, @best_images_taxon_to_xml["phylum"] if @best_images_taxon_to_xml["phylum"]
    xml.dwc :Class, @best_images_taxon_to_xml["class"] if @best_images_taxon_to_xml["class"]
    xml.dwc :Order, @best_images_taxon_to_xml["order"] if @best_images_taxon_to_xml["order"]
    xml.dwc :Family, @best_images_taxon_to_xml["family"] if @best_images_taxon_to_xml["family"]
    xml.dwc :Genus, @best_images_taxon_to_xml["genus"] if @best_images_taxon_to_xml["genus"]
    xml.dwc :ScientificName, @best_images_taxon_to_xml["ScientificName"]
    
    for item in @array_to_render
      xml.dataObject do 
        xml.dc :identifier, item["identifier"]
        xml.dataType "http://purl.org/dc/dcmitype/StillImage"
        xml.mimeType item["mimeType"]
        for agent in item["agents"] 
          xml.agent agent["fullName"], :homepage => agent["homepage"], :logoURL => agent["logoURL"], :role => agent["role"]
        end
        xml.dcterms :created,  item["created"]  
        xml.dcterms :modified, item["modified"]
        xml.dc :language, item["language"]      
        xml.license  item["license"]           
        xml.dc :rights, item["rights"]        
        xml.dcterms :rightsHolder, item["rightsHolder"]        
        xml.dcterms :bibliographicCitation, item["bibliographicCitation"]
        xml.source       item["source"]
        xml.dc :description,  item["description"]  
        xml.mediaURL     item["mediaURL"] 
        xml.thumbnailURL item["thumbnailURL"]
      end
    end
  end
end
