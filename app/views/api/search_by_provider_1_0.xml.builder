xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.results do
  @json_response.each do |r|
    xml.eol_page_id r['eol_page_id']
  end
end
