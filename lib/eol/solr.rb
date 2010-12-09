module EOL
  module Solr
    def self.query_lucene(solr_endpoint, query, options = {})
      query_url = solr_endpoint + '/select/?wt=json&q='
      query_url << URI.encode(%Q[{!lucene}#{query}])
      query_url << "&sort=" << URI.encode(%Q[#{options[:sort]}]) unless options[:sort].blank?
      query_url << "&start=#{options[:start]}" unless options[:start].blank?
      query_url << "&rows=#{options[:rows]}" unless options[:rows].blank?
      query_url << "&fl=" << URI.encode(%Q[#{options[:fields]}]) unless options[:fields].blank?

      res = open(query_url).read
      JSON.load res
    end
  end
end