module EOL
  module Solr
    module Search
      # Returns an array of result hashes, using will_paginate.  Don't use paginate_all_by_solr directly, as that will either fail
      # or cause duplicate queries.
      # TODO - use a class rather than a class variable for search_results_for
      def search_with_pagination(query, options = {})
        options[:page]        ||= 1
        options[:per_page]    ||= 10
        options[:search_type] ||= :common_name
        query_prefix, query_suffix = query.split(":")[0], query.split(":")[1..-1].join(":")
        clean_query = query_prefix + ":" + query_suffix.gsub('_', ' ') # Handles some of the "clean" URL "ids" that may get passed in.
        res = solr_search(clean_query, options)
        data = res['response']['docs']
        total_results = res['response']['numFound']
        data.paginate :page => options[:page], :per_page => options[:per_page], :total_entries => total_results
      end
      
      private
      
      # Returns the actual search results object.  Generally, you will want to use search_with_pagination instead.
      # Restult looks like this:
      # [{"top_image_id"=>1, "preferred_scientific_name"=>["Procyon lotor"], "published"=>[true], "scientific_name"=>["Procyon
      # lotor"], "supercedure_id"=>[0], "vetted_id"=>[1], "taxon_concept_id"=>[14]}]
      def solr_search(query, options = {})
        url =  $SOLR_SERVER + '/select/?version=2.2&indent=on&wt=json&q='
        url << URI.encode(%Q[{!lucene} #{query} AND published:1 AND supercedure_id:0])
        limit  = options[:per_page] ? options[:per_page].to_i : 10
        page = options[:page] ? options[:page].to_i : 1
        offset = page_to_offset(page, limit)
        url << '&start=' << URI.encode(offset.to_s)
        url << '&rows='  << URI.encode(limit.to_s)
        res = open(url).read
        JSON.load res
      end
      
      def offset_to_page(offset, limit)
        raise "offset and limit should be integers" unless offset.class == Fixnum and limit.class == Fixnum
        offset / limit + 1
      end

      def page_to_offset(page, limit)
        raise "page and limit should be integers" unless  page.class == Fixnum and limit.class == Fixnum
        (page - 1) * limit
      end


    end
  end
end
