xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"

xml.feed "xmlns" => "http://www.w3.org/2005/Atom",
  "xmlns:os".to_sym => "http://a9.com/-/spec/opensearch/1.1/" do

  search_api_url = url_for(:controller => 'api', :action => 'search', :id => @search_term, :only_path => false);
  xml.title "Encyclopedia of Life search: #{@search_term}"
  xml.link :href => search_api_url
  xml.updated
  xml.author do
    xml.name "Encyclopedia of Life"
  end
  xml.id search_api_url
  xml.os :totalResults, @json_response['totalResults']
  xml.os :startIndex, @json_response['startIndex']
  xml.os :itemsPerPage, @json_response['itemsPerPage']
  xml.os :Query, :role => "request", :searchTerms => @search_term, :startPage => @page

  xml.link :rel => "alternate", :href => "#{search_api_url}/", :type => "application/atom+xml"
  xml.link :rel => "first", :href => @json_response['first'], :type => "application/atom+xml" if @json_response['first']
  xml.link :rel => "previous", :href => @json_response['previous'], :type => "application/atom+xml" if @json_response['previous']
  xml.link :rel => "self", :href => @json_response['self'], :type => "application/atom+xml" if @json_response['self']
  xml.link :rel => "next", :href => @json_response['next'], :type => "application/atom+xml" if @json_response['next']
  xml.link :rel => "last", :href => @json_response['last'], :type => "application/atom+xml" if @json_response['last']
  xml.link :rel => "search", :href => "#{request.protocol}#{request.host_with_port}#{asset_path('/opensearchdescription.xml')}", :type => "application/opensearchdescription+xml"

  for result in @json_response['results']
    xml.entry do
      xml.title result['title']
      xml.link :href => result['link']
      xml.id result['id']
      xml.updated
      xml.content result['content']
    end
  end
end
