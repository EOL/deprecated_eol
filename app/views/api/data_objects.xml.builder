xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response "xmlns" => "http://www.eol.org/transfer/content/0.3",
  "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/",
  "xmlns:dwc".to_sym => "http://rs.tdwg.org/dwc/dwcore/",
  "xmlns:dcterms".to_sym => "http://purl.org/dc/terms/",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
  "xsi:schemaLocation" => "http://www.eol.org/transfer/content/0.3 http://services.eol.org/schema/content_0_3.xsd" do                                                                                                               
  
  unless @details_hash.blank?
    xml.dataObject do
      xml.dc :identifier, @details_hash["guid"]
      xml.dataType @details_hash["data_type"]
      xml.mimeType @details_hash["mime_type"]
      
      for agent in @details_hash["agents"]
        xml.agent agent["full_name"], :homepage => agent["homepage"], :role => agent["role"]
      end
      
      xml.dcterms :created, @details_hash["object_created_at"] unless @details_hash["object_created_at"].blank?
      xml.dcterms :modified, @details_hash["updated_at"] unless @details_hash["updated_at"].blank?
      xml.dc :title, @details_hash["object_title"] unless @details_hash["object_title"].blank?
      xml.dc :language, @details_hash["language"] unless @details_hash["language"].blank?
      xml.license @details_hash["license"] unless @details_hash["license"].blank?
      xml.dc :rights, @details_hash["rights_statement"] unless @details_hash["rights_statement"].blank?
      xml.dcterms :rightsHolder, @details_hash["rights_holder"] unless @details_hash["rights_holder"].blank?
      xml.dcterms :bibliographicCitation, @details_hash["bibliographic_citation"] unless @details_hash["bibliographic_citation"].blank?
      # leaving out audience
      xml.dc :source, @details_hash["source_url"] unless @details_hash["source_url"].blank?
      xml.subject @details_hash["subject"] unless @details_hash["subject"].blank?
      xml.dc :description, @details_hash["description"] unless @details_hash["description"].blank?
      xml.mediaURL @details_hash["object_url"] unless @details_hash["object_url"].blank?
      xml.mediaURL DataObject.image_cache_path(@details_hash["object_cache_url"], :large) unless @details_hash["object_cache_url"].blank?
      xml.thumbnailURL @details_hash["thumbnail_url"] unless @details_hash["thumbnail_url"].blank?
      xml.location @details_hash["location"] unless @details_hash["location"].blank?
      
      unless @details_hash['latitude']=="0" && @details_hash['longitude']=="0" && @details_hash['altitude']=="0"
        xml.geo :Point do
          xml.geo :lat, @details_hash['latitude'] unless @details_hash['latitude']=="0"
          xml.geo :long, @details_hash['longitude'] unless @details_hash['longitude']=="0"
          xml.geo :alt, @details_hash['altitude'] unless @details_hash['altitude']=="0"
        end
      end
      
      for ref in @details_hash["refs"] 
        xml.reference ref["full_reference"]
      end
    end
  end
end
