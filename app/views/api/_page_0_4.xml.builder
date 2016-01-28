unless page.blank?
  xml.taxon do
    xml.dc :identifier, page['identifier'] if page['identifier']
    xml.dwc :ScientificName, page['scientificName'] if page['scientificName']
    xml.dwc :exemplar, DataObject.find_by_id_or_guid(params[:id]).is_exemplar_for?(page['identifier']) if DataObject.find_by_id_or_guid(params[:id])

    page['synonyms'].each do |synonym|
      xml.synonym synonym['synonym'], :relationship => synonym['relationship']
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
      page['taxonConcepts'].each do |tc|
        xml.dwct :Taxon do
          xml.dc :identifier, tc['sourceIdentifier']
          xml.dwct :taxonID, url_for(:controller => 'api', :action => 'hierarchy_entries', :id => tc['identifier'], :only_path => false)
          xml.dwct :scientificName, tc['scientificName']
          xml.dwct :nameAccordingTo, tc['nameAccordingTo']
          xml.dwct :taxonRank, tc['taxonRank']

          entry = tc['hierarchyEntry']
          canonical_form_words = entry.name.canonical_form.string.split(/ /)
          count_canonical_words = canonical_form_words.length
          if Rank.kingdom.group_members.include?(entry.rank) &&  count_canonical_words == 1
            xml.dwct :kingdom, canonical_form_words[0]
          elsif Rank.phylum.group_members.include?(entry.rank) &&  count_canonical_words == 1
            xml.dwct :phylum, canonical_form_words[0]
          elsif Rank.class_rank.group_members.include?(entry.rank) &&  count_canonical_words == 1
            xml.dwct :class, canonical_form_words[0]
          elsif Rank.order.group_members.include?(entry.rank) &&  count_canonical_words == 1
            xml.dwct :order, canonical_form_words[0]
          elsif Rank.family.group_members.include?(entry.rank) &&  count_canonical_words == 1
            xml.dwct :family, canonical_form_words[0]
          elsif Rank.genus.group_members.include?(entry.rank) &&  count_canonical_words == 1
            xml.dwct :genus, canonical_form_words[0]
          elsif Rank.species.group_members.include?(entry.rank) && count_canonical_words == 2
            xml.dwct :genus, canonical_form_words[0]
            xml.dwct :specificEpithet, canonical_form_words[1]
          elsif Rank.subspecies.group_members.include?(entry.rank) && count_canonical_words == 3
            xml.dwct :genus, canonical_form_words[0]
            xml.dwct :specificEpithet, canonical_form_words[1]
            xml.dwct :infraspecificEpithet, canonical_form_words[2]
          end
        end
      end
    end if page['taxonConcepts']

    page['dataObjects'].each do |data_object|
      xml << render(partial: 'data_object', layout: false, locals: { :data_object_hash => data_object } )
    end if page['dataObjects']
  end
end
