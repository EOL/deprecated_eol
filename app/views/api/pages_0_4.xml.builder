xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.response "xmlns" => "http://www.eol.org/transfer/content/0.3",
  "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/",
  "xmlns:dwc".to_sym => "http://rs.tdwg.org/dwc/dwcore/",
  "xmlns:dcterms".to_sym => "http://purl.org/dc/terms/",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xmlns:geo" => "http://www.w3.org/2003/01/geo/wgs84_pos#",
  "xmlns:dwct" => "http://rs.tdwg.org/dwc/terms/",
  "xsi:schemaLocation" => "http://www.eol.org/transfer/content/0.3 http://services.eol.org/schema/content_0_3.xsd" do

   if @json_response.is_a?(Array)
    xml.taxonConcepts do
	  @json_response.each do |page|
	    xml << render(partial: 'page_0_4', layout: false, locals: { :page => page.values[0] } )
      end
    end
  else
    xml << render(partial: 'page_0_4', layout: false, locals: { :page => @json_response } )
  end
end