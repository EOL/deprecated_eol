xml.dataType data_object_hash['dataType']

if params[:details]
  xml.mimeType data_object_hash['mimeType'] unless data_object_hash['mimeType'].blank?
  data_object_hash['agents'].each do |agent|
    xml.agent agent['full_name'], :homepage => agent['homepage'], :role => agent['role']
  end
  xml.dcterms :created, data_object_hash['created'] unless data_object_hash['created'].blank?
  xml.dcterms :modified, data_object_hash['modified'] unless data_object_hash['modified'].blank?
  xml.dc :title, data_object_hash['title'] unless data_object_hash['title'].blank?
  xml.dc :language, data_object_hash['language'] unless data_object_hash['language'].blank?
  xml.license data_object_hash['license'] unless data_object_hash['license'].blank?
  xml.dc :rights, data_object_hash['rights'] unless data_object_hash['rights'].blank?
  xml.dcterms :rightsHolder, data_object_hash['rightsHolder'] unless data_object_hash['rightsHolder'].blank?
  xml.dcterms :bibliographicCitation, data_object_hash['bibliographicCitation'] unless data_object_hash['bibliographicCitation'].blank?
  unless data_object_hash['audience'].blank?
    data_object_hash['audience'].each do |label|
      xml.audience label
    end
  end
  xml.dc :source, data_object_hash['source'] unless data_object_hash['source'].blank?
end

xml.subject data_object_hash['subject'] unless data_object_hash['subject'].blank?

if params[:details]
  xml.dc :description, data_object_hash['description'] unless data_object_hash['description'].blank?
  xml.mediaURL data_object_hash['mediaURL'] unless data_object_hash['mediaURL'].blank?
  xml.mediaURL data_object_hash['eolMediaURL'] unless data_object_hash['eolMediaURL'].blank?
  xml.thumbnailURL data_object_hash['eolThumbnailURL'] unless data_object_hash['eolThumbnailURL'].blank?
  xml.location data_object_hash['location'] unless data_object_hash['location'].blank?

  unless data_object_hash['latitude'].blank? && data_object_hash['longitude'].blank? && data_object_hash['altitude'].blank?
    xml.geo :Point do
      xml.geo :lat, data_object_hash['latitude'] unless data_object_hash['latitude'].blank?
      xml.geo :long, data_object_hash['longitude'] unless data_object_hash['longitude'].blank?
      xml.geo :alt, data_object_hash['altitude'] unless data_object_hash['altitude'].blank?
    end
  end

  data_object_hash['references'].each do |ref|
    xml.reference ref
  end
end

xml.additionalInformation do
  xml.dataSubtype data_object_hash['dataSubtype'] unless data_object_hash['dataSubtype'].blank?
  xml.vettedStatus data_object_hash['vettedStatus'] unless data_object_hash['vettedStatus'].blank?
  xml.dataRating data_object_hash['dataRating'] unless data_object_hash['dataRating'].blank?
  xml.dataObjectVersionID data_object_hash['dataObjectVersionID'] unless data_object_hash['dataObjectVersionID'].blank?
  xml.height data_object_hash['height'] unless data_object_hash['height'].blank?
  xml.width data_object_hash['width'] unless data_object_hash['width'].blank?
  xml.crop_x data_object_hash['crop_x'] unless data_object_hash['crop_x'].blank?
  xml.crop_y data_object_hash['crop_y'] unless data_object_hash['crop_y'].blank?
  xml.crop_height data_object_hash['crop_height'] unless data_object_hash['crop_height'].blank?
  xml.crop_width data_object_hash['crop_width'] unless data_object_hash['crop_width'].blank?
end
