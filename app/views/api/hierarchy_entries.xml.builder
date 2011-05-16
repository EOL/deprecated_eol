xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.DataSet "xmlns" => "http://www.tdwg.org/schemas/tcs/1.01",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xsi:schemaLocation" => "http://www.tdwg.org/schemas/tcs/1.01 http://www.tdwg.org/standards/117/files/TCS101/v101.xsd" do                                                                                                               
  
  unless @hierarchy_entry.blank?
    xml.MetaData do
    end
    
    xml.TaxonNames do
      xml.TaxonName(:id => "n#{@hierarchy_entry.name.id}") do
        xml.Simple @hierarchy_entry.name.string
        xml.Rank @hierarchy_entry.rank.label.firstcap, :code => @hierarchy_entry.rank.tcs_code unless @hierarchy_entry.rank.nil?
        xml.CanonicalName do
          xml.Simple @hierarchy_entry.canonical_form.string
        end
        xml.ProviderSpecificData do
          xml.NameSources do
            for agent_role in @hierarchy_entry.agents_roles
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
      xml.TaxonConcept(:id => "#{@hierarchy_entry.id}") do
        xml.Name @hierarchy_entry.name.string, :scientific => 'true', :ref => "n#{@hierarchy_entry.name.id}"
        xml.Rank @hierarchy_entry.rank.label.firstcap, :code => @hierarchy_entry.rank.tcs_code unless @hierarchy_entry.rank.nil?
        xml.TaxonRelationships do
          if parent = @hierarchy_entry.parent
            xml.TaxonRelationship(:type => 'is child taxon of') do
              xml.ToTaxonConcept(:ref => url_for(:controller => 'api', :action => 'hierarchy_entries', :id => parent.id, :only_path => false), :linktype => 'external')
            end
          end
          
          for child in @hierarchy_entry.children
            xml.TaxonRelationship(:type => 'is parent taxon of') do
              xml.ToTaxonConcept(:ref => url_for(:controller => 'api', :action => 'hierarchy_entries', :id => child.id, :only_path => false), :linktype => 'external')
            end
          end
          
          if @include_synonyms
            for synonym in @hierarchy_entry.scientific_synonyms
              xml.TaxonRelationship(:type => 'has synonym') do
                xml.ToTaxonConcept(:ref => url_for(:controller => 'api', :action => 'synonyms', :id => synonym.id, :only_path => false), :linktype => 'external')
              end
            end
          end
          
          if @include_common_names
            for common_name in @hierarchy_entry.common_names
              xml.TaxonRelationship(:type => 'has vernacular') do
                xml.ToTaxonConcept(:ref => url_for(:controller => 'api', :action => 'synonyms', :id => common_name.id, :only_path => false), :linktype => 'external')
              end
            end
          end
          
        end
      end
    end
  end
end
