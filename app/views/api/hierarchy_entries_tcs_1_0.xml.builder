xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.DataSet "xmlns" => "http://www.tdwg.org/schemas/tcs/1.01",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xsi:schemaLocation" => "http://www.tdwg.org/schemas/tcs/1.01 http://www.tdwg.org/standards/117/files/TCS101/v101.xsd" do

  xml.MetaData do
  end

  xml.TaxonNames do
    xml.TaxonName(:id => "n#{@json_response['hierarchy_entry'].name.id}") do
      xml.Simple @json_response['scientificName']
      xml.Rank @json_response['taxonRank'], :code => @json_response['hierarchy_entry'].rank.tcs_code unless @json_response['hierarchy_entry'].rank.nil?
      xml.CanonicalName do
        xml.Simple @json_response['hierarchy_entry'].name.canonical_form.string
      end
      xml.ProviderSpecificData do
        xml.NameSources do
          for agent_role in @json_response['hierarchy_entry'].agents_roles
            xml.NameSource do
              xml.Simple agent_role.agent.full_name
              xml.Role agent_role.agent_role.label
            end
          end
        end
      end
    end
  end

  xml.TaxonConcepts do
    xml.TaxonConcept(:id => @json_response['taxonID']) do
      xml.Name @json_response['scientificName'], :scientific => 'true', :ref => "n#{@json_response['hierarchy_entry'].name.id}"
      xml.Rank @json_response['taxonRank'], :code => @json_response['hierarchy_entry'].rank.tcs_code unless @json_response['hierarchy_entry'].rank.nil?
      xml.TaxonRelationships do
        if parent = @json_response['ancestors'].last
          xml.TaxonRelationship(:type => 'is child taxon of') do
            xml.ToTaxonConcept(:ref => url_for(:controller => 'api', :action => 'hierarchy_entries', :id => parent['taxonID'], :render => 'tcs', :only_path => false), :linktype => 'external')
          end
        end

        @json_response['children'].each do |child|
          xml.TaxonRelationship(:type => 'is parent taxon of') do
            xml.ToTaxonConcept(:ref => url_for(:controller => 'api', :action => 'hierarchy_entries', :id => child['taxonID'], :render => 'tcs', :only_path => false), :linktype => 'external')
          end
        end
        
      	@json_response['descendants'].each do |descendant|
      	  xml.TaxonRelationship(:type => 'is ancestor taxon of') do
            xml.ToTaxonConcept(:ref => url_for(controller: 'api', action: 'hierarchy_entries', id: descendant[:taxonID], render: 'tcs', only_path: false), linktype: 'external')
          end
	    end

        @json_response['synonyms'].each do |synonym|
          xml.TaxonRelationship(:type => 'has synonym') do
            xml.ToTaxonConcept(:ref => url_for(:controller => 'api', :action => 'synonyms', :id => synonym['id'], :only_path => false), :linktype => 'external')
          end
        end

        @json_response['vernacularNames'].each do |common_name|
          xml.TaxonRelationship(:type => 'has vernacular') do
            xml.ToTaxonConcept(:ref => url_for(:controller => 'api', :action => 'synonyms', :id => common_name['id'], :only_path => false), :linktype => 'external')
          end
        end
      end
    end
  end
end
