xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.DataSet "xmlns" => "http://www.tdwg.org/schemas/tcs/1.01",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xsi:schemaLocation" => "http://www.tdwg.org/schemas/tcs/1.01 http://www.tdwg.org/standards/117/files/TCS101/v101.xsd" do                                                                                                               
  
  unless @hierarchy_entry.blank?
    xml.MetaData do
    end
    
    xml.TaxonNames do
      xml.TaxonName(:id => "n#{@hierarchy_entry.name_object.id}") do
        xml.Simple @hierarchy_entry.name_object.string
        xml.Rank @hierarchy_entry.rank.label.firstcap, :code => @hierarchy_entry.rank.tcs_code unless @hierarchy_entry.rank.nil?
        xml.CanonicalName do
          xml.Simple @hierarchy_entry.canonical_form.string
        end
        xml.ProviderSpecificData do
          xml.NameSources do
            for agent_role in @hierarchy_entry.agents_roles
              xml.NameSource do
                xml.Simple agent_role.agent.display_name
                xml.Role agent_role.agent_role.label
              end
            end
          end
        end
      end
    end
    
    xml.TaxonConcepts do
      xml.TaxonConcept(:id => "#{@hierarchy_entry.id}") do
        xml.Name @hierarchy_entry.name_object.string, :scientific => 'true', :ref => "n#{@hierarchy_entry.name_object.id}"
        xml.Rank @hierarchy_entry.rank.label.firstcap, :code => @hierarchy_entry.rank.tcs_code unless @hierarchy_entry.rank.nil?
        xml.TaxonRelationships do
          if parent = @hierarchy_entry.parent
            xml.TaxonRelationship(:type => 'is child taxon of') do
              xml.ToTaxonConcept(:ref => "http://#{$SITE_DOMAIN_OR_IP}/api/hierarchy_entries/#{parent.id}", :linktype => 'external')
            end
          end
          
          for child in @hierarchy_entry.children
            xml.TaxonRelationship(:type => 'is parent taxon of') do
              xml.ToTaxonConcept(:ref => "http://#{$SITE_DOMAIN_OR_IP}/api/hierarchy_entries/#{child.id}", :linktype => 'external')
            end
          end
          
          for synonym in @hierarchy_entry.synonyms
            relation = SynonymRelation.common_name_ids.include?(synonym.synonym_relation_id) ? 'has vernacular' : 'has synonym'
            xml.TaxonRelationship(:type => relation) do
              xml.ToTaxonConcept(:ref => "http://#{$SITE_DOMAIN_OR_IP}/api/synonyms/#{synonym.id}", :linktype => 'external')
            end
          end
        end
      end
    end
  end
end
