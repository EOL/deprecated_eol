if params[:render] == 'tcs'
  xml << render(:template => 'api/hierarchy_entries_tcs_1_0')
else
  xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

  xml.dwr :DarwinRecordSet,
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      "xmlns:dcterms"       => "http://purl.org/dc/terms/",
      "xmlns:dwc"           => "http://rs.tdwg.org/dwc/terms/",
      "xmlns:dwr"           => "http://rs.tdwg.org/dwc/dwcrecord/",
      "xmlns:dc"            => "http://purl.org/dc/elements/1.1/",
      "xsi:schemaLocation"  => "http://rs.tdwg.org/dwc/dwcrecord/  http://rs.tdwg.org/dwc/xsd/tdwg_dwc_classes.xsd" do

    for ancestor in @json_response['ancestors']
      xml.dwc :Taxon do
        xml.dc :identifier, ancestor['sourceIdentifier']
        xml.dwc :taxonID, ancestor['taxonID']
        xml.dwc :parentNameUsageID, ancestor['parentNameUsageID']
        xml.dwc :taxonConceptID, ancestor['taxonConceptID']
        xml.dwc :scientificName, ancestor['scientificName']
        xml.dwc :taxonRank, ancestor['taxonRank']
        xml.dc :source, ancestor['source'] unless ancestor['source'].blank?
      end
    end
    
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

    xml.dwc :Taxon do
      xml.dc :identifier, @json_response['sourceIdentifier']
      xml.dwc :taxonID, @json_response['taxonID']
      xml.dwc :parentNameUsageID, @json_response['parentNameUsageID']
      xml.dwc :taxonConceptID, @json_response['taxonConceptID']
      xml.dwc :scientificName, @json_response['scientificName']
      xml.dwc :taxonRank, @json_response['taxonRank']
      xml.dc :source, @json_response['source'] unless @json_response['source'].blank?

      entry = @json_response['hierarchy_entry']
      canonical_form_words = entry.name.canonical_form.string.split(/ /)
      count_canonical_words = canonical_form_words.length
      if Rank.kingdom.group_members.include?(entry.rank) && count_canonical_words == 1
        xml.dwc :kingdom, canonical_form_words[0]
      elsif Rank.phylum.group_members.include?(entry.rank) && count_canonical_words == 1
        xml.dwc :phylum, canonical_form_words[0]
      elsif Rank.class_rank.group_members.include?(entry.rank) && count_canonical_words == 1
        xml.dwc :class, canonical_form_words[0]
      elsif Rank.order.group_members.include?(entry.rank) && count_canonical_words == 1
        xml.dwc :order, canonical_form_words[0]
      elsif Rank.family.group_members.include?(entry.rank) && count_canonical_words == 1
        xml.dwc :family, canonical_form_words[0]
      elsif Rank.genus.group_members.include?(entry.rank) && count_canonical_words == 1
        xml.dwc :genus, canonical_form_words[0]
      elsif Rank.species.group_members.include?(entry.rank) && count_canonical_words == 2
        xml.dwc :genus, canonical_form_words[0]
        xml.dwc :specificEpithet, canonical_form_words[1]
      elsif Rank.subspecies.group_members.include?(entry.rank) && count_canonical_words == 3
        xml.dwc :genus, canonical_form_words[0]
        xml.dwc :specificEpithet, canonical_form_words[1]
        xml.dwc :infraspecificEpithet, canonical_form_words[2]
      end

      @json_response['vernacularNames'].each do |common_name|
        xml.dwc :vernacularName, common_name['vernacularName'], 'xml:lang'.to_sym => common_name['language']
      end

      @json_response['nameAccordingTo'].each do |according_to|
        xml.dwc :nameAccordingTo, according_to
      end
    end

    @json_response['synonyms'].each do |synonym|
      xml.dwc :Taxon do
        xml.dwc :parentNameUsageID, @json_response['taxonID']
        xml.dwc :scientificName, synonym['scientificName']
        xml.dwc :taxonomicStatus, synonym['taxonomicStatus']
      end
    end

    @json_response['children'].each do |child|
      xml.dwc :Taxon do
        xml.dc :identifier, child['sourceIdentifier']
        xml.dwc :taxonID, child['taxonID']
        xml.dwc :parentNameUsageID, child['parentNameUsageID']
        xml.dwc :taxonConceptID, child['taxonConceptID']
        xml.dwc :scientificName, child['scientificName']
        xml.dwc :taxonRank, child['taxonRank']
        xml.dc :source, child['source'] unless child['source'].blank?
      end
    end
  end
end