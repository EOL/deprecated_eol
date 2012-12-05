xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response "xmlns" => "http://www.eol.org/transfer/content/0.3",
  "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/",
  "xmlns:dwc".to_sym => "http://rs.tdwg.org/dwc/dwcore/",
  "xmlns:dcterms".to_sym => "http://purl.org/dc/terms/",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
  "xmlns:dwct" => "http://rs.tdwg.org/dwc/terms/",
  "xsi:schemaLocation" => "http://www.eol.org/transfer/content/0.3 http://services.eol.org/schema/content_0_3.xsd" do                                                                                                               
  
  unless taxon_concept.blank?
    xml.taxon do
      xml.dc :identifier, taxon_concept.id
      xml.dwc :ScientificName, taxon_concept.entry.name.string
      
      if params[:synonyms]
        for syn in taxon_concept.scientific_synonyms
          relation = syn.synonym_relation ? syn.synonym_relation.label : ''
          xml.synonym syn.name.string, 'relationship'.to_sym => relation
        end
      end
      if params[:common_names]
        for tcn in taxon_concept.common_names
          lang = tcn.language ? tcn.language.iso_639_1 : ''
          preferred = (tcn.preferred == 1) ? true : nil
          attributes = {}
          attributes['xml:lang'.to_sym] = lang unless lang.blank?
          attributes[:eol_preferred] = preferred unless preferred.blank?
          xml.commonName tcn.name.string, attributes
        end
      end
      
      unless taxon_concept.curated_hierarchy_entries.blank?
        xml.additionalInformation do
          for entry in taxon_concept.curated_hierarchy_entries
            xml.dwct :Taxon do
              xml.dc :identifier, entry.identifier unless entry.identifier.blank?
              xml.dwct :taxonID, url_for(:controller => 'api', :action => 'hierarchy_entries', :id => entry.id, :only_path => false)
              xml.dwct :scientificName, entry.name.string
              xml.dwct :nameAccordingTo, entry.hierarchy.label
              xml.dwct :taxonRank, entry.rank.label.firstcap unless entry.rank.blank?
              
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
        end
      end
      
      for data_object in data_objects
        if params[:details]
          xml << render(:partial => 'data_object', :layout => false, :locals => { :data_object => data_object, :minimal => false } )
        else
          xml << render(:partial => 'data_object', :layout => false, :locals => { :data_object => data_object, :minimal => true } )
        end
      end
    end
  end
end
