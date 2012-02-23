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
    
    def self.add_standard_instance_to_docs!(klass, docs, primary_key_field_name, options = {})
      ids = docs.map{ |d| d[primary_key_field_name] }.compact
      return if ids.blank?
      instances = klass.find_all_by_id(ids, :include => options[:includes], :select => options[:selects])
      # TODO: making an exception here for Comments as you can only use the Comment.preload_associations syntax
      # to get the poloymorphic associations
      if klass == Comment
        Comment.preload_associations(instances, :parent)
      end
      docs.each do |d|
        d['instance'] = instances.detect{ |i| i.id == d[primary_key_field_name].to_i }
      end
    end
  end
end