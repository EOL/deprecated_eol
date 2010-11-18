xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.results do
  @hierarchies.each do |h|
    xml.provider_hierarchy h.label, :id => h.id
  end
end
