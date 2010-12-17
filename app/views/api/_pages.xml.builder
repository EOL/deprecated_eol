xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response "xmlns" => "http://www.eol.org/transfer/content/0.3",
  "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/",
  "xmlns:dwc".to_sym => "http://rs.tdwg.org/dwc/dwcore/",
  "xmlns:dcterms".to_sym => "http://purl.org/dc/terms/",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
  "xmlns:dwct" => "http://rs.tdwg.org/dwc/terms/",
  "xsi:schemaLocation" => "http://www.eol.org/transfer/content/0.3 http://services.eol.org/schema/content_0_3.xsd" do                                                                                                               
  
  unless details_hash.blank?
    xml.taxon do
      xml.dc :identifier, details_hash['id']
      xml.dwc :ScientificName, details_hash['scientific_name']
      
      for common_name in details_hash["common_names"]
        xml.commonName common_name['name_string'], 'xml:lang'.to_sym => common_name['iso_639_1']
      end
      
      unless details_hash['curated_hierarchy_entries'].blank?
        xml.additionalInformation do
          for entry in details_hash['curated_hierarchy_entries']
            xml.dwct :Taxon do
              xml.dc :identifier, entry.identifier unless entry.identifier.blank?
              xml.dwct :taxonID, url_for(:controller => 'api', :action => 'hierarchy_entries', :id => entry.id, :only_path => false)
              xml.dwct :scientificName, entry.name_object.string
              xml.dwct :nameAccordingTo, entry.hierarchy.label
              xml.dwct :taxonRank, entry.rank.label.firstcap unless entry.rank.nil?
              
              canonical_form_words = entry.name_object.canonical_form.string.split(/ /)
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
      
      for object in details_hash["data_objects"]
        if data_object_details
          xml << render(:partial => 'data_object.xml.builder', :layout => false, :locals => { :object_hash => object, :minimal => false } )
        else
          xml << render(:partial => 'data_object.xml.builder', :layout => false, :locals => { :object_hash => object, :minimal => true } )
        end
      end
    end
  end
end
