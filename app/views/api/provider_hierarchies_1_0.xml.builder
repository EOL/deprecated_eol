xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.results do
  @json_response.each do |h|
    xml.hierarchy h['label'], :id => h['id']
  end
end
