xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.dwr :DarwinRecordSet,
    "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
    "xmlns:dcterms"       => "http://purl.org/dc/terms/",
    "xmlns:dwc"           => "http://rs.tdwg.org/dwc/terms/",
    "xmlns:dwr"           => "http://rs.tdwg.org/dwc/dwcrecord/",
    "xmlns:dc"            => "http://purl.org/dc/elements/1.1/",
    "xsi:schemaLocation"  => "http://rs.tdwg.org/dwc/dwcrecord/  http://rs.tdwg.org/dwc/xsd/tdwg_dwc_classes.xsd" do
  
  for ancestor in @ancestors
    xml.dwc :Taxon do
      xml.dc :identifier, ancestor.identifier unless ancestor.identifier.blank?
      xml.dwc :taxonID, ancestor.id
      xml.dwc :parentNameUsageID, ancestor.parent_id
      xml.dwc :taxonConceptID, ancestor.taxon_concept_id
      xml.dwc :scientificName, ancestor.name.string.firstcap
      xml.dwc :taxonRank, ancestor.rank.label unless ancestor.rank_id == 0 || ancestor.rank.blank?
    end
  end
  
  xml.dwc :Taxon do
    xml.dc :identifier, @hierarchy_entry.identifier unless @hierarchy_entry.identifier.blank?
    xml.dwc :taxonID, @hierarchy_entry.id
    xml.dwc :parentNameUsageID, @hierarchy_entry.parent_id
    xml.dwc :taxonConceptID, @hierarchy_entry.taxon_concept_id
    xml.dwc :scientificName, @hierarchy_entry.name.string
    xml.dwc :taxonRank, @hierarchy_entry.rank.label.firstcap unless @hierarchy_entry.rank.nil?
    
    canonical_form_words = @hierarchy_entry.name.canonical_form.string.split(/ /)
    count_canonical_words = canonical_form_words.length
    if Rank.kingdom.group_members.include?(@hierarchy_entry.rank) &&  count_canonical_words == 1
      xml.dwc :kingdom, canonical_form_words[0]
    elsif Rank.phylum.group_members.include?(@hierarchy_entry.rank) &&  count_canonical_words == 1
      xml.dwc :phylum, canonical_form_words[0]
    elsif Rank.class_rank.group_members.include?(@hierarchy_entry.rank) &&  count_canonical_words == 1
      xml.dwc :class, canonical_form_words[0]
    elsif Rank.order.group_members.include?(@hierarchy_entry.rank) &&  count_canonical_words == 1
      xml.dwc :order, canonical_form_words[0]
    elsif Rank.family.group_members.include?(@hierarchy_entry.rank) &&  count_canonical_words == 1
      xml.dwc :family, canonical_form_words[0]
    elsif Rank.genus.group_members.include?(@hierarchy_entry.rank) &&  count_canonical_words == 1
      xml.dwc :genus, canonical_form_words[0]
    elsif Rank.species.group_members.include?(@hierarchy_entry.rank) && count_canonical_words == 2
      xml.dwc :genus, canonical_form_words[0]
      xml.dwc :specificEpithet, canonical_form_words[1]
    elsif Rank.subspecies.group_members.include?(@hierarchy_entry.rank) && count_canonical_words == 3
      xml.dwc :genus, canonical_form_words[0]
      xml.dwc :specificEpithet, canonical_form_words[1]
      xml.dwc :infraspecificEpithet, canonical_form_words[2]
    end
    
    if @include_common_names
      for common_name in @hierarchy_entry.common_names
        language = common_name.language ? common_name.language.iso_639_1 : ''
        xml.dwc :vernacularName, common_name.name.string.firstcap, 'xml:lang'.to_sym => language
      end
    end
    
    for agent_role in @hierarchy_entry.agents_roles
      xml.dwc :nameAccordingTo, agent_role.agent.full_name
    end
  end
  
  if @include_synonyms
    for synonym in @hierarchy_entry.scientific_synonyms
      xml.dwc :Taxon do
        xml.dwc :parentNameUsageID, @hierarchy_entry.id
        xml.dwc :scientificName, synonym.name.string.firstcap
        unless synonym.synonym_relation.blank?
          xml.dwc :taxonomicStatus, synonym.synonym_relation.label
        else
          xml.dwc :taxonomicStatus, 'synonym'
        end
      end
    end
  end
  
  for child in @children
    xml.dwc :Taxon do
      xml.dc :identifier, child.identifier unless child.identifier.blank?
      xml.dwc :taxonID, child.id
      xml.dwc :parentNameUsageID, child.parent_id
      xml.dwc :taxonConceptID, child.taxon_concept_id
      xml.dwc :scientificName, child.name.string.firstcap
      xml.dwc :taxonRank, child.rank.label unless child.rank_id == 0 || child.rank.blank?
    end
  end
end
