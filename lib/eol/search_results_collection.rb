module EOL
  class SearchResultsCollection

    include Enumerable

    attr_reader :results
    attr_reader :total_results

    def initialize(results, options = {})
      @results       = results
      @total_results = options[:total_results] || results.length
      @type          = options[:type] # Used to flag special behavior
      @querystring   = options[:querystring]
      # We don't actually want to do this next step unless we *know* the results are based on TaxonConcept... but, for the
      # time being, we always are.  In the future, this will want to be abstracted out, so that we inherit all the common
      # behaviour and add this behaviour if it's a TC-based search:
      update_results_with_current_data
    end

    def each
      @results.each {|i| yield i }
    end

    def paginate(options)
      WillPaginate::Collection.create(options[:page], options[:per_page], @total_results) do |pager|
        pager.replace @results
      end
    end

    def update_results_with_current_data
      return nil unless @results
      @results.each do |res|
        tc = TaxonConcept.find(res['taxon_concept_id'][0])
        res.merge!({
          'title' => tc.title(@session_hierarchy),
          'preferred_common_name' => (res["preferred_common_name"] || tc.common_name(@session_hierarchy) || '')
          })
        # TODO - actually, this is too hard-coded.  Ideally, we would know which results to look through, which to match to
        # the search results, and which to leave alone... but that's a lot of work!  :D
        if @type == :common # Common name search, we want to show them the best matched common name:
          find_matched_common_name(res)
        else
          res.merge!('best_matched_common_name' => res['preferred_common_name']) # Show them the preferred name
        end
      end
    end

    def find_matched_common_name(search_result)
      common_names = search_result['common_name'].clone
      querystring  = @querystring.normalize.split(' ').to_set
      if common_names # TODO - this else clause is really a separate method to "repair" missing common names
        # TODO - this smells like a class method:
        common_names.map! do |name|
          name_set  = name.normalize.split(' ').to_set
          intersect = name_set.intersection(@querystring) # TODO - make sure querystring members are all downcased.
          [name, intersect.size]
        end
        common_names = common_names.sort_by {|i| i[1]}.reverse 
        # if we have only 0s, return the preferred name:
        if common_names.first[1] == 0
          search_result['best_matched_common_name'] = search_result['preferred_common_name']
        else
          # if the best matches *include* the preferred name, use that:
          best_matches = common_names.select {|i| i[1] == common_names.first[1]}.map {|i| i[0].normalize }
          if best_matches.include?(search_result['preferred_common_name'].normalize)
            search_result['best_matched_common_name'] = search_result['preferred_common_name']
          else # Otherwise, just use the best match:
            search_result['best_matched_common_name'] = common_names.first[0]
          end
        end
      else # Common names were bogus:
        search_result['common_name'] = ['']
        search_result['best_matched_common_name'] = ''
      end
    end

  end
end

