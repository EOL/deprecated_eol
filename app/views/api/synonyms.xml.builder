xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.DataSet "xmlns" => "http://www.tdwg.org/schemas/tcs/1.01",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xsi:schemaLocation" => "http://www.tdwg.org/schemas/tcs/1.01 http://www.tdwg.org/standards/117/files/TCS101/v101.xsd" do                                                                                                               
  
  unless @synonym.blank?
    xml.MetaData do
    end
    
    xml.TaxonNames do
      xml.TaxonName(:id => "n#{@synonym.name.id}") do
        xml.Simple @synonym.name.string
        unless SynonymRelation.common_name_ids.include?(@synonym.synonym_relation_id)
          xml.CanonicalName do
            xml.Simple @synonym.name.canonical_form.string
          end
        end
        xml.ProviderSpecificData do
          xml.NameSources do
            for agent_role in @synonym.agents_roles
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
      xml.TaxonConcept(:id => "s#{@synonym.id}") do
        xml.Name @synonym.name.string, :scientific => 'true', :ref => "n#{@synonym.name.id}"
      end
    end
  end
end
