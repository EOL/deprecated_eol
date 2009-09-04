# http://services.eol.org/schema/documentation_0_2.pdf
# http://localhost:3000/pages/25/best_images.xml

xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.highly_rated_images do                                                                                                               
  xml.title "Encyclopedia of Life #{@title}"

  xml.taxon_concept do
    xml.identifier      @best_images_taxon_to_xml["identifier"]
    xml.Kingdom					@best_images_taxon_to_xml["kingdom"]
    xml.Phylum					@best_images_taxon_to_xml["phylum"]
    xml.Class					  @best_images_taxon_to_xml["class"]
    xml.Order					  @best_images_taxon_to_xml["order"]
    xml.Family					@best_images_taxon_to_xml["family"]
    xml.Genus 					@best_images_taxon_to_xml["genus"]
    xml.ScientificName  @best_images_taxon_to_xml["ScientificName"]
  end
  
  xml.images do
    for item in @array_to_render
      xml.image do 
        xml.identifier item["identifier"]
        # item["dc:identifier"]
        xml.mimeType item["mimeType"]     
        xml.agent do
          xml.homepage item["homepage"] 
          xml.logoURL  item["logoURL"]  
          xml.role     item["role"]     
        end
  
        xml.created  item["created"]  
        xml.modified item["modified"]
        xml.language item["language"]      
        xml.license  item["license"]           
        xml.rights   item["rights"]        
        xml.rightsHolder item["rightsHolder"]        
        xml.bibliographicCitation item["bibliographicCitation"]
        xml.source       item["source"]       
        xml.description  item["description"]  
        xml.mediaURL     item["mediaURL"] 
        xml.thumbnailURL item["thumbnailURL"]
      end
    end
  end
end
