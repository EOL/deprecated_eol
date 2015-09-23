xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response "xmlns" => "http://www.eol.org/transfer/content/1.0",
  "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/",
  "xmlns:dwc".to_sym => "http://rs.tdwg.org/dwc/terms/",
  "xmlns:dcterms".to_sym => "http://purl.org/dc/terms/",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
  "xsi:schemaLocation" => "http://www.eol.org/transfer/content/1.0 http://services.eol.org/schema/content_1_0.xsd" do

  xml.taxonConcept do
    xml.taxonConceptID @json_response['identifier']
    xml.dwc :scientificName, @json_response['scientificName']

    @json_response['synonyms'].each do |synonym|
      xml.synonym synonym['synonym'], :relationship => synonym['relationship'], :resource => synonym['resource'] 
    end

    @json_response['vernacularNames'].each do |common_name|
      attributes = {}
      attributes['xml:lang'.to_sym] = common_name['language'] unless common_name['language'].blank?
      attributes[:eol_preferred] = common_name['eol_preferred'] unless common_name['eol_preferred'].blank?
      xml.commonName common_name['vernacularName'], attributes
    end

    @json_response['references'].each do |ref|
      xml.reference ref
    end

    xml.additionalInformation do
      xml.richness_score @json_response['richness_score']
      @json_response['taxonConcepts'].each do |tc|
        xml.taxon do
          xml.dc :identifier, tc['sourceIdentfier']
          xml.dwc :taxonID, tc['identifier']
          xml.dwc :scientificName, tc['scientificName']
          xml.dwc :nameAccordingTo, tc['nameAccordingTo']
          xml.dwc :taxonRank, tc['taxonRank']
        end
      end
    end
  end

  @json_response['dataObjects'].each do |data_object|
    xml << render(partial: 'data_object_1_0', layout: false, locals: { :data_object_hash => data_object, :taxon_concept_id => @json_response['identifier'] } )
  end
end
