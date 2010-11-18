xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.results do
  @results.each do |r|
    xml.eol_page_id r.taxon_concept_id
  end
end
