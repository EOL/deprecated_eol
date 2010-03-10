unless object_hash.blank?
  xml.dataObject do
    xml.dc :identifier, object_hash["guid"]
    xml.dataType object_hash["data_type"]
    xml.mimeType object_hash["mime_type"]
    
    unless object_hash["agents"].nil?
      for agent in object_hash["agents"]
        xml.agent agent["full_name"], :homepage => agent["homepage"], :role => agent["role"].downcase
      end
    end
    
    xml.dcterms :created, object_hash["object_created_at"] unless object_hash["object_created_at"].blank?
    xml.dcterms :modified, object_hash["updated_at"] unless object_hash["updated_at"].blank?
    xml.dc :title, object_hash["object_title"] unless object_hash["object_title"].blank?
    xml.dc :language, object_hash["language"] unless object_hash["language"].blank?
    xml.license object_hash["license"] unless object_hash["license"].blank?
    xml.dc :rights, object_hash["rights_statement"] unless object_hash["rights_statement"].blank?
    xml.dcterms :rightsHolder, object_hash["rights_holder"] unless object_hash["rights_holder"].blank?
    xml.dcterms :bibliographicCitation, object_hash["bibliographic_citation"] unless object_hash["bibliographic_citation"].blank?
    # leaving out audience
    xml.dc :source, object_hash["source_url"] unless object_hash["source_url"].blank?
    xml.subject object_hash["subject"] unless object_hash["subject"].blank?
    xml.dc :description, object_hash["description"] unless object_hash["description"].blank?
    xml.mediaURL object_hash["object_url"] unless object_hash["object_url"].blank?
    xml.mediaURL DataObject.image_cache_path(object_hash["object_cache_url"], :large) unless object_hash["object_cache_url"].blank?
    xml.thumbnailURL object_hash["thumbnail_url"] unless object_hash["thumbnail_url"].blank?
    xml.location object_hash["location"] unless object_hash["location"].blank?
    
    unless object_hash['latitude']=="0" && object_hash['longitude']=="0" && object_hash['altitude']=="0"
      xml.geo :Point do
        xml.geo :lat, object_hash['latitude'] unless object_hash['latitude']=="0"
        xml.geo :long, object_hash['longitude'] unless object_hash['longitude']=="0"
        xml.geo :alt, object_hash['altitude'] unless object_hash['altitude']=="0"
      end
    end
    
    unless object_hash["refs"].nil?
      for ref in object_hash["refs"] 
        xml.reference ref["full_reference"]
      end
    end
  end
end
