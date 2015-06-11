if params[:render] == 'tcs'
  xml << render(:template => 'api/hierarchy_entries_descendants_tcs_1_0')
else
  xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

  xml.dwr :DarwinRecordSet,
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      "xmlns:dcterms"       => "http://purl.org/dc/terms/",
      "xmlns:dwc"           => "http://rs.tdwg.org/dwc/terms/",
      "xmlns:dwr"           => "http://rs.tdwg.org/dwc/dwcrecord/",
      "xmlns:dc"            => "http://purl.org/dc/elements/1.1/",
      "xsi:schemaLocation"  => "http://rs.tdwg.org/dwc/dwcrecord/  http://rs.tdwg.org/dwc/xsd/tdwg_dwc_classes.xsd" do

    xml.dwc :Descendants do
      @json_response['descendants'].each do |descendant|
	    xml.dwc :Taxon do
	      xml.dc :identifier, descendant[:sourceIdentifier]
	      xml.dwc :taxonID, descendant[:taxonID]
	      xml.dwc :parentNameUsageID, descendant[:parentNameUsageID]
	      xml.dwc :taxonConceptID, descendant[:taxonConceptID]
	      xml.dwc :scientificName, descendant[:scientificName]
	      xml.dwc :taxonRank, descendant[:taxonRank]
	      xml.dc :source, descendant[:source] unless descendant[:source].blank?
	    end
	  end
    end
  end
end