xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response "xmlns" => "http://www.eol.org/transfer/content/0.3",
  "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/",
  "xmlns:dwc".to_sym => "http://rs.tdwg.org/dwc/dwcore/",
  "xmlns:dcterms".to_sym => "http://purl.org/dc/terms/",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
  "xmlns:dwct" => "http://rs.tdwg.org/dwc/terms/",
  "xsi:schemaLocation" => "http://www.eol.org/transfer/content/0.3 http://services.eol.org/schema/content_0_3.xsd" do

  xml.taxon do
    xml.dc :identifier, @json_response['identifier'] if @json_response['identifier']
    xml.dwc :ScientificName, @json_response['scientificName'] if @json_response['scientificName']
    xml.dwc :exemplar, DataObject.find_by_id_or_guid(params[:id]).is_exemplar?(@json_response['identifier']) if DataObject.find_by_id_or_guid(params[:id])

    @json_response['synonyms'].each do |synonym|
      xml.synonym synonym['synonym'], :relationship => synonym['relationship']
    end if @json_response['synonyms']

    @json_response['vernacularNames'].each do |common_name|
      attributes = {}
      attributes['xml:lang'.to_sym] = common_name['language'] unless common_name['language'].blank?
      attributes[:eol_preferred] = common_name['eol_preferred'] unless common_name['eol_preferred'].blank?
      xml.commonName common_name['vernacularName'], attributes
    end if @json_response['vernacularNames']

    @json_response['references'].each do |ref|
      xml.reference ref
    end if @json_response['references']

    xml.additionalInformation do
      @json_response['taxonConcepts'].each do |tc|
        xml.dwct :Taxon do
          xml.dc :identifier, tc['sourceIdentfier']
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
    end if @json_response['taxonConcepts']

    @json_response['dataObjects'].each do |data_object|
      xml << render(partial: 'data_object', layout: false, locals: { :data_object_hash => data_object } )
    end if @json_response['dataObjects']
  end
end