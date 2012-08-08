xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response "xmlns" => "http://www.eol.org/transfer/content/1.0",
  "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/",
  "xmlns:dwc".to_sym => "http://rs.tdwg.org/dwc/terms/",
  "xmlns:dcterms".to_sym => "http://purl.org/dc/terms/",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
  "xsi:schemaLocation" => "http://www.eol.org/transfer/content/1.0 http://services.eol.org/schema/content_1_0.xsd" do                                                                                                               
  
  unless taxon_concept.blank?
    xml.taxonConcept do
      xml.taxonConceptID taxon_concept.id
      xml.dwc :ScientificName, taxon_concept.entry.name.string
      
      if params[:synonyms]
        for syn in taxon_concept.synonyms
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
      
      xml.additionalInformation do
        xml.richness_score taxon_concept.taxon_concept_metric.richness_for_display(5) rescue 0
        unless taxon_concept.curated_hierarchy_entries.blank?
          for entry in taxon_concept.curated_hierarchy_entries
            xml.taxon do
              xml.dc :identifier, entry.identifier unless entry.identifier.blank?
              xml.dwc :taxonID, entry.id
              xml.dwc :scientificName, entry.name.string
              xml.dwc :nameAccordingTo, entry.hierarchy.label
              xml.dwc :taxonRank, entry.rank.label.firstcap unless entry.rank.blank?
            end
          end
        end
      end
    end
    
    for data_object in data_objects
      if params[:details]
        xml << render(:partial => 'data_object_1_0.xml.builder', :layout => false, :locals => { :data_object => data_object, :taxon_concept_id => taxon_concept.id, :minimal => false } )
      else
        xml << render(:partial => 'data_object_1_0.xml.builder', :layout => false, :locals => { :data_object => data_object, :taxon_concept_id => taxon_concept.id, :minimal => true } )
      end
    end
  end
end
