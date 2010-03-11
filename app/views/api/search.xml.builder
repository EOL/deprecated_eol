xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.feed "xmlns" => "http://www.w3.org/2005/Atom",
  "xmlns:os".to_sym => "http://a9.com/-/spec/opensearch/1.1/" do                                                                                                               
  
  xml.title "Encyclopedia of Life search: #{@search_term}"
  xml.link :href => "http://www.eol.org/search?q=#{@search_term}"
  xml.updated
  xml.author do
    xml.name "Encyclopedia of Life"
  end
  xml.id "http://www.eol.org/search?q=#{@search_term}"
  xml.os :totalResults, @results.total_entries
  xml.os :startIndex, ((@results.current_page - 1) * @results.per_page) + 1
  xml.os :itemsPerPage, @results.per_page
  xml.os :Query, :role => "request", :searchTerms => @search_term, :startPage => @page
  xml.link :rel => "alternate", :href => "/search?q=#{@search_term}", :type => "text/html"
  xml.link :rel => "first", :href => "/search?q=#{@search_term}&format=atom&page=1", :type => "text/html" if @page <= @last_page
  xml.link :rel => "previous", :href => "/search?q=#{@search_term}&format=atom&page=#{@page-1}", :type => "text/html" if @page > 1 && @page <= @last_page
  xml.link :rel => "self", :href => "/search?q=#{@search_term}&format=atom&page=#{@page}", :type => "text/html" if @page <= @last_page
  xml.link :rel => "next", :href => "/search?q=#{@search_term}&format=atom&page=#{@page+1}", :type => "text/html" if @page < @last_page
  xml.link :rel => "last", :href => "/search?q=#{@search_term}&format=atom&page=#{@last_page}", :type => "text/html" if @page <= @last_page
  xml.link :rel => "search", :href => "/opensearchdescription.xml", :type => "application/opensearchdescription+xml"
  
  for result in @results
    xml.entry do
      xml.title result['preferred_scientific_name'][0]
      xml.link :href => "http://www.eol.org/pages/#{result['taxon_concept_id'][0]}"
      xml.id "http://www.eol.org/pages/#{result['taxon_concept_id'][0]}"
      xml.updated
      xml.content result['common_name'][0], :type => "text"
    end
  end
end
