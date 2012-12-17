xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.DataSet "xmlns" => "http://www.tdwg.org/schemas/tcs/1.01",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xsi:schemaLocation" => "http://www.tdwg.org/schemas/tcs/1.01 http://www.tdwg.org/standards/117/files/TCS101/v101.xsd" do

  xml.MetaData do
  end

  xml.TaxonNames do
    xml.TaxonName(:id => "n#{@json_response['synonym'].name.id}") do
      xml.Simple @json_response['synonym'].name.string
      unless SynonymRelation.common_name_ids.include?(@json_response['synonym'].synonym_relation_id)
        xml.CanonicalName do
          xml.Simple @json_response['synonym'].name.canonical_form.string
        end
      end
      xml.ProviderSpecificData do
        xml.NameSources do
          for agent_role in @json_response['synonym'].agents_roles
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
    xml.TaxonConcept(:id => "s#{@json_response['synonym'].id}") do
      # common_name
      if SynonymRelation.common_name_ids.include?(@json_response['synonym'].synonym_relation_id)
        language = @json_response['synonym'].language.nil? ? '' : @json_response['synonym'].language.iso_639_1
        xml.Name @json_response['synonym'].name.string, :scientific => 'false', :language => language, :ref => "n#{@json_response['synonym'].name.id}"
      else #synonym
        xml.Name @json_response['synonym'].name.string, :scientific => 'true', :ref => "n#{@json_response['synonym'].name.id}"
      end
    end
  end
end
