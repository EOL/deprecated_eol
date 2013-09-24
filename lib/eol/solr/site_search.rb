module EOL
  module Solr
    class SiteSearch

      # its used for a wildcard search if we're not looking for everything, or all concepts
      def self.types_to_show_all
        [ 'Image', 'Video', 'Sound', 'User', 'Community', 'Collection', 'ContentPage' ]
      end

      def self.search_with_pagination(query, options = {})
        options[:page]        ||= 1
        options[:per_page]    ||= 25
        options[:per_page]      = 25 if options[:per_page] == 0
        
        response = solr_search(query, options)
        
        total_results = response['grouped']['resource_unique_key']['ngroups']
        query_time = response['grouped']['QTime']
        return_hash = { :time => query_time,
                        :total => total_results }
        
        return_hash[:results] = []
        response['grouped']['resource_unique_key']['groups'].each do |g|
          return_hash[:results] << g['doclist']['docs'][0]
        end
        add_resource_instances!(return_hash[:results], options)
        add_best_match_keywords!(return_hash[:results], query)
        return_hash[:results] = WillPaginate::Collection.create(options[:page], options[:per_page], total_results) do |pager|
           pager.replace(return_hash[:results])
        end
        
        return_hash[:facets] = {}
        facets = response['facet_counts']['facet_fields']['resource_type']
        facets.each_with_index do |rt, index|
          next if index % 2 == 1 # if its odd, skip this. Solr has a strange way of returning the facets in JSON
          return_hash[:facets][rt] = facets[index+1]
        end
        
        return_hash[:suggestions] = []
        suggestions = response['spellcheck']['suggestions']
        unless suggestions.blank?
          suggestions[1]['suggestion'].each do |suggestion|
            return_hash[:suggestions] << suggestion unless suggestion.downcase == query.downcase
          end
        end
        
        return return_hash
      end

      private

      def self.add_resource_instances!(docs, options)
        add_community!(docs.select{ |d| d['resource_type'].include?('Community') }, options)
        add_collection!(docs.select{ |d| d['resource_type'].include?('Collection') }, options)
        add_user!(docs.select{ |d| d['resource_type'].include?('User') }, options)
        add_taxon_concept!(docs.select{ |d| d['resource_type'].include?('TaxonConcept') }, options)
        add_data_object!(docs.select{ |d| d['resource_type'].include?('DataObject') }, options)
        add_content_page!(docs.select{ |d| d['resource_type'].include?('ContentPage') }, options)
      end

      def self.add_community!(docs, options)
        ids = docs.map{ |d| d['resource_id'] }
        return if ids.blank?
        instances = Community.find_all_by_id(ids)
        docs.each do |d|
          d['instance'] = instances.detect{ |i| i.id == d['resource_id'].to_i }
        end
      end

      def self.add_collection!(docs, options)
        ids = docs.map{ |d| d['resource_id'] }
        return if ids.blank?
        instances = Collection.find_all_by_id(ids, :include => [ :users, :communities ])
        docs.each do |d|
          d['instance'] = instances.detect{ |i| i.id == d['resource_id'].to_i }
        end
      end

      def self.add_user!(docs, options)
        ids = docs.map{ |d| d['resource_id'] }
        return if ids.blank?
        instances = User.find_all_by_id(ids)
        docs.each do |d|
          d['instance'] = instances.detect{ |i| i.id == d['resource_id'].to_i }
        end
      end

      def self.add_content_page!(docs, options)
        ids = docs.map{ |d| d['resource_id'] }
        return if ids.blank?
        instances = ContentPage.find_all_by_id(ids)
        docs.each do |d|
          d['instance'] = instances.detect{ |i| i.id == d['resource_id'].to_i }
        end
      end

      def self.add_taxon_concept!(docs, options)
        includes = [
          { :preferred_entry => 
            { :hierarchy_entry => { :name => :ranked_canonical_form } } }, 
          :preferred_common_names ]
        ids = docs.map{ |d| d['resource_id'] }
        return if ids.blank?
        instances = TaxonConcept.find_all_by_id(ids)
        TaxonConcept.preload_associations(instances, includes)
        docs.each do |d|
          d['instance'] = instances.detect{ |i| i.id == d['resource_id'].to_i }
        end
      end

      def self.add_data_object!(docs, options)
        # TODO: do some preloading
        ids = docs.map{ |d| d['resource_id'] }
        return if ids.blank?
        instances = DataObject.find_all_by_id(ids)
        docs.each do |d|
          d['instance'] = instances.detect{ |i| i.id == d['resource_id'].to_i }
        end
      end

      def self.add_best_match_keywords!(docs, querystring)
        querystring_set = querystring.normalize.split(' ').to_set
        docs.each_with_index do |d, index|
          best_match = nil
          best_intersection_size = 0
          d['keyword'].each do |k|
            keyword_set  = k.normalize.split(' ').to_set
            intersection_size = keyword_set.intersection(querystring_set).size
            if intersection_size > best_intersection_size || best_intersection_size == 0
              best_match = k
              best_intersection_size = intersection_size
            end
          end
          docs[index]['best_keyword_match'] = best_match
        end
      end

      def self.solr_search(query, options = {})
        url =  $SOLR_SERVER + $SOLR_SITE_SEARCH_CORE + '/select/?wt=json&q=' + CGI.escape(%Q[{!lucene}])
        lucene_query = ''
        escaped_query = query.gsub(/"/, "\\\"")
        # if its a wildcard search and we're not looking for everything, or all concepts, do a real wildcard search
        if query == '*' && options[:type] && options[:type].size == 1 && types_to_show_all.include?(options[:type].first)
          lucene_query << '*:*'
          if [ 'Image', 'Sound', 'Video' ].include?(options[:type].first)
            options[:sort_by] = 'newest' # TODO: oops - no data_rating field?
          else
            options[:sort_by] = 'newest'
          end
        else
          # create initial query, 'exact' or 'contains'
          query.fix_spaces
          if options[:exact]
            lucene_query << "keyword_exact:\"#{escaped_query}\"^5"
          else
            lucene_query << "(keyword_exact:\"#{escaped_query}\"^5 OR #{self.keyword_field_for_term(query)}:\"#{escaped_query}\"~10^2)"
          end
        
          # add search suggestions and weight them way higher. Suggested searches are currently always TaxonConcepts
          search_suggestions(query, options[:exact]).each do |ss|
            lucene_query << " OR (resource_id:\"#{ss.taxon_id}\"^300 AND resource_type:TaxonConcept)"
          end
        end
        
        # now compile all the query bits with proper logic
        url << CGI.escape(%Q[(#{lucene_query})])
        
        if id = filter_by_taxon_concept_id(options)
          url << CGI.escape(%Q[ AND (ancestor_taxon_concept_id:#{id})])
        end
        
        url << CGI.escape(%Q[ AND _val_:richness_score^200])
        
        # add facet filtering
        if options[:type] && !options[:type].include?('all')
          options[:type].map!{ |t| t.camelize }
          url << '&fq=resource_type:' + CGI.escape(%Q[#{options[:type].join(' OR resource_type:')}])
        end
        
        # add spellchecking - its using the spellcheck.q option because the main query main have gotten too complicated
        url << '&spellcheck.q=' + CGI.escape(%Q[#{escaped_query}]) + '&spellcheck=true&spellcheck.count=500'
        
        # add grouping and faceting
        url << "&group=true&group.field=resource_unique_key&group.ngroups=true&facet.field=resource_type&facet=on"
        # we also want to get back the relevancy score
        url << "&fl=score"
        # add sorting
        if options[:sort_by] == 'newest'
          url << '&sort=date_modified+desc'
        elsif options[:sort_by] == 'oldest'
          url << '&sort=date_modified+asc'
        elsif options[:sort_by] == 'score'
          url << '&sort=resource_weight+asc,score+desc'
        end
        
        # add paging
        limit  = options[:per_page] ? options[:per_page].to_i : 10
        page = options[:page] ? options[:page].to_i : 1
        offset = (page - 1) * limit
        url << '&start=' << URI.encode(offset.to_s)
        url << '&rows='  << URI.encode(limit.to_s)
        res = open(url).read
        JSON.load res
      end

      def self.search_suggestions(querystring, exact = false)
        suggested_results = []
        unless exact
          pluralized = querystring.pluralize
          singular   = querystring.singularize
          suggested_results = SearchSuggestion.find_all_by_term_and_active(singular, true, :order => 'sort_order') +
                              SearchSuggestion.find_all_by_term_and_active(pluralized, true, :order => 'sort_order')
        end
        
        # bacteria has a singular bacterium and a plural bacterias so we need to search on the original term too
        if exact || (querystring != pluralized && querystring != singular)
          suggested_results += SearchSuggestion.find_all_by_term_and_active(querystring, true, :order => 'sort_order')
        end
        suggested_results
      end

      # returns 'nonsense' when lookups were requested but failed, that way the search ultimately fails
      def self.filter_by_taxon_concept_id(options={})
        filter_taxon_concept_id = nil
        if options[:filter_by_taxon_concept_id]
          filter_taxon_concept_id = options[:filter_by_taxon_concept_id]
        elsif options[:filter_by_hierarchy_entry_id]
          hierarchy_entry = HierarchyEntry.find_by_id(options[:filter_by_hierarchy_entry_id], :select => 'taxon_concept_id')
          filter_taxon_concept_id = (hierarchy_entry.blank?) ? 'nonsense' : hierarchy_entry.taxon_concept_id
        elsif !options[:filter_by_string].blank?
          response = search_with_pagination(options[:filter_by_string],
            :page => 1, :per_page => 1, :type => ['TaxonConcept'], :exact => true)
          filter_taxon_concept_id = response[:results][0]['resource_id'].to_i rescue 'nonsense'
        end
        filter_taxon_concept_id
      end

      def self.get_facet_counts(query, options={})
        url =  $SOLR_SERVER + $SOLR_SITE_SEARCH_CORE + '/select/?wt=json&q=' + CGI.escape(%Q[{!lucene}])
        escaped_query = query.gsub(/"/, "\\\"")
        if query == '*'
          url << CGI.escape('*:* AND (resource_type:' + types_to_show_all.join(' OR resource_type:') + ')')
        else
          # create initial query, 'exact' or 'contains'
          if options[:exact]
            url << CGI.escape("keyword_exact:\"#{escaped_query}\"")
          else
            url << CGI.escape("(keyword_exact:\"#{escaped_query}\" OR #{self.keyword_field_for_term(query)}:\"#{escaped_query}\")")
          end
          
          # add search suggestions and weight them way higher. Suggested searches are currently always TaxonConcepts
          search_suggestions(query, options[:exact]).each do |ss|
            url << CGI.escape(" OR (resource_id:\"#{ss.taxon_id}\" AND resource_type:TaxonConcept)")
          end
        end
        
        url << "&group=true&group.field=resource_unique_key&group.ngroups=true&facet.field=resource_type&facet=on&rows=0"
        res = open(url).read
        response = JSON.load(res)
        
        facets = {}
        f = response['facet_counts']['facet_fields']['resource_type']
        f.each_with_index do |rt, index|
          next if index % 2 == 1 # if its odd, skip this. Solr has a strange way of returning the facets in JSON
          facets[rt] = f[index+1]
        end
        total_results = response['grouped']['resource_unique_key']['ngroups']
        facets['All'] = total_results
        facets
      end
      
      def self.keyword_field_for_term(search_term)
        return 'keyword_cn' if search_term.contains_chinese?
        return 'keyword_ar' if search_term.contains_arabic?
        'keyword'
      end
    end
  end
end
