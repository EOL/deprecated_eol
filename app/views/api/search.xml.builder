xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.feed "xmlns" => "http://www.w3.org/2005/Atom",
  "xmlns:os".to_sym => "http://a9.com/-/spec/opensearch/1.1/" do                                                                                                               
  
  xml.title "Encyclopedia of Life search: #{@search_term}"
  xml.link :href => url_for(:controller => 'taxa', :action => 'search', :q => @search_term, :only_path => false)
  xml.updated
  xml.author do
    xml.name "Encyclopedia of Life"
  end
  xml.id url_for(:controller => 'taxa', :action => 'search', :q => @search_term, :only_path => false)
  xml.os :totalResults, @results.total_entries
  xml.os :startIndex, ((@page) * @per_page) - @per_page + 1
  xml.os :itemsPerPage, @per_page
  xml.os :Query, :role => "request", :searchTerms => @search_term, :startPage => @page
  
  search_api_url = url_for(:controller => 'api', :action => 'search', :id => @search_term, :only_path => false);
  xml.link :rel => "alternate", :href => "#{search_api_url}/", :type => "application/atom+xml"
  xml.link :rel => "first", :href => "#{search_api_url}?page=1", :type => "application/atom+xml" if @page <= @last_page
  xml.link :rel => "previous", :href => "#{search_api_url}?page=#{@page-1}", :type => "application/atom+xml" if @page > 1 && @page <= @last_page
  xml.link :rel => "self", :href => "#{search_api_url}?page=#{@page}", :type => "application/atom+xml" if @page <= @last_page
  xml.link :rel => "next", :href => "#{search_api_url}?page=#{@page+1}", :type => "application/atom+xml" if @page < @last_page
  xml.link :rel => "last", :href => "#{search_api_url}?page=#{@last_page}", :type => "application/atom+xml" if @page <= @last_page
  xml.link :rel => "search", :href => url_for(:controller => "opensearchdescription.xml", :only_path => false), :type => "application/opensearchdescription+xml"
  
  for result in @results
    xml.entry do
      xml.title result['best_matched_scientific_name']
      xml.link :href => url_for(:controller => 'taxa', :action => 'show', :id => result['id'], :only_path => false)
      xml.id result['id']
      xml.updated
      xml.content result['scientific_name'].join(', ')+"\n\n"+result['common_name'].join(', '), :type => "text" if result['common_name']
    end
  end
end
