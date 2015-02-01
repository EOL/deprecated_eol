# TODO - consider sunspot. it's widely used, nicely documented, handles boost, has a nice DSL, includes highlights. Autocomplete, RSpec matchers and
# DelayedJob plugins avilable. It could greatly simplify EOL's code.

module EOL
  module Solr
    def self.rebuild_all
      EOL::Solr::DataObjectsCoreRebuilder.begin_rebuild
      EOL::Solr::SiteSearchCoreRebuilder.begin_rebuild
      EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild
      # EOL::Solr::BHLCoreRebuilder.new().begin_rebuild
    end

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
      if docs.class == Hash
        ids = docs.map{ |k,d| d[primary_key_field_name] }.compact
      else
        ids = docs.map{ |d| d[primary_key_field_name] }.compact
      end
      return if ids.blank?
      instances = klass.find_all_by_id(ids, :include => options[:includes], :select => options[:selects])
      # TODO: making an exception here for Comments as you can only use the Comment.preload_associations syntax
      # to get the poloymorphic associations
      if klass == Comment
        Comment.preload_associations(instances, :parent)
      end
      if docs.class == Hash
        docs.each do |k,d|
          d['instance'] = instances.detect{ |i| i.id == d[primary_key_field_name].to_i }
        end
      else
        docs.each do |d|
          d['instance'] = instances.detect{ |i| i.id == d[primary_key_field_name].to_i }
        end
      end
    end

  end
end
