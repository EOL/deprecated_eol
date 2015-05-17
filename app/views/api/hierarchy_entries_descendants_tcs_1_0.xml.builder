xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.DataSet "xmlns" => "http://www.tdwg.org/schemas/tcs/1.01",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xsi:schemaLocation" => "http://www.tdwg.org/schemas/tcs/1.01 http://www.tdwg.org/standards/117/files/TCS101/v101.xsd" do

  xml.MetaData do
  end


  xml.TaxonConcepts do
    xml.TaxonRelationships do
      @json_response['descendants'].each do |descendant|
        xml.TaxonRelationship(type: 'is ancestor taxon of') do
          xml.ToTaxonConcept(ref: url_for(controller: 'api', action: 'hierarchy_entries', id: descendant[:taxonID], render: 'tcs', only_path: false), linktype: 'external')
        end
      end
    end
  end
end
