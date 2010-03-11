module EOL
  module Solr
    module Search
      # Returns an array of result hashes, using will_paginate.  Don't use paginate_all_by_solr directly, as that will either fail
      # or cause duplicate queries.
      # TODO - use a class rather than a class variable for search_results_for
      def search_with_pagination(query, options = {})
        options[:page]        ||= 1
        options[:per_page]    ||= 10
        options[:per_page]      = 10 if options[:per_page] == 0
        options[:search_type] ||= :common_name
        clean_query = options[:escape_query_underscore] ? query.gsub('_', ' ') : query # Handles some of the "clean" URL "ids" that may get passed in.
        querystring = ''
        if clean_query =~ /:/ # This was passed in as a prepared querystring TODO - this s/b a separate method
          querystring  = clean_query
          @@field_spec = /\w+:/
          query        = clean_query.gsub(@@field_spec, '') # TODO - this may not handle complex querystrings well.
        else # This was just a raw string, we need to make a query out of it:
          querystring = prepare_querystring(clean_query, options)
        end
        res  = solr_search(querystring, options)
        data = EOL::SearchResultsCollection.new(res['response']['docs'],
                                                options.merge(
                                                  :total_results => res['response']['numFound'],
                                                  :querystring   => query))
        data.paginate(options)
      end
      
      private
      
      # TODO - clearly, I don't like the hard-coded field.  We want to pass in the search_field as an option... but in a nice
      # way.  Later.
      def prepare_querystring(query, options)
        if options[:type] == :all
          literal_query = "scientific_name:\"#{query}\" OR common_name:\"#{query}\""
        else
          field = options[:type] == :common ? 'common_name' : 'scientific_name'
          literal_query = "#{field}:\"#{query}\""
        end
        query = query.gsub /\s+/, ' '
        query = query.split(' ').map {|w| "+#{w}"}.join(' ')
        query = "(#{literal_query})" #OR #{field}:(#{query}))"
      end

      # Returns the actual search results object.  Generally, you will want to use search_with_pagination instead.
      # Result looks like this:
      # [{"top_image_id"=>1, "preferred_scientific_name"=>["Procyon lotor"], "published"=>[true], "scientific_name"=>["Procyon
      # lotor"], "supercedure_id"=>[0], "vetted_id"=>[1], "taxon_concept_id"=>[14]}]
      def solr_search(query, options = {})
        url =  $SOLR_SERVER + '/select/?version=2.2&indent=on&wt=json&q='
        url << URI.encode(%Q[{!lucene} #{query} AND published:1 AND supercedure_id:0])
        limit  = options[:per_page] ? options[:per_page].to_i : 10
        page = options[:page] ? options[:page].to_i : 1
        offset = (page - 1) * limit
        url << '&start=' << URI.encode(offset.to_s)
        url << '&rows='  << URI.encode(limit.to_s)
        #puts 'URA solr' + url
        res = open(url).read
        JSON.load res
      end
    end
  end
end
