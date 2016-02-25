unless page.blank?
  xml.taxonConcept do
	xml.taxonConceptID page['identifier']
	xml.dwc :scientificName, page['scientificName']

    page['synonyms'].each do |synonym|
	  xml.synonym synonym['synonym'], :relationship => synonym['relationship'], :resource => synonym['resource']
	end if page['synonyms']

	page['vernacularNames'].each do |common_name|
	  attributes = {}
	  attributes['xml:lang'.to_sym] = common_name['language'] unless common_name['language'].blank?
	  attributes[:eol_preferred] = common_name['eol_preferred'] unless common_name['eol_preferred'].blank?
	  xml.commonName common_name['vernacularName'], attributes
	end if page['vernacularNames']

	page['references'].each do |ref|
	  xml.reference ref
	end if page['references']

	xml.additionalInformation do
	  xml.richness_score page['richness_score']
	  page['taxonConcepts'].each do |tc|
	    xml.taxon do
	      xml.dc :identifier, tc['sourceIdentifier']
	      xml.dwc :taxonID, tc['identifier']
	      xml.dwc :scientificName, tc['scientificName']
	      xml.dwc :nameAccordingTo, tc['nameAccordingTo']
	      xml.dwc :taxonRank, tc['taxonRank']
	    end
	  end if page['taxonConcepts']
	end
  end

  page['dataObjects'].each do |data_object|
    xml << render(partial: 'data_object_1_0', layout: false, locals: { :data_object_hash => data_object, :taxon_concept_id => page['identifier'] } )
  end if page['dataObjects']
end
