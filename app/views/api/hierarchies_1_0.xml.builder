xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response "xmlns:dwc" => "http://rs.tdwg.org/dwc/terms/",
  "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do

  xml.metadata do
    xml.dc :title, @json_response['title']
    xml.dc :contributor, @json_response['contributor']
    xml.dc :dateSubmitted, @json_response['dateSubmitted']
    xml.dc :source, @json_response['source']
  end

  for root in @json_response['roots']
    xml.dwc :Taxon do
      xml.dc :identifier, root['sourceIdentifier']
      xml.dwc :taxonID, root['taxonID']
      xml.dwc :parentNameUsageID, root['parentNameUsageID']
      xml.dwc :taxonConceptID, root['taxonConceptID']
      xml.dwc :scientificName, root['scientificName']
      xml.dwc :taxonRank, root['taxonRank']
    end
  end
end
