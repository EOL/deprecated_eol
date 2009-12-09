module EOL
  # A relatively simple Enumerable class for handling the results from EOL's Solr search, since there's some sorting and
  # re-populating of the data that needs to happen before anything is displayed.
  class SearchResultsCollection

    include Enumerable

    attr_reader :results
    attr_reader :total_results

    def initialize(results, options = {})
      @results       = results
      @total_results = options[:total_results] || results.length
      @type          = options[:type] # Used to flag special behavior that gets the 'best' common name match
      @querystring   = options[:querystring]

      # The follwing are not yet options, but will be someday:
      @best_match_field_name         = 'best_matched_common_name'
      @default_best_match_field_name = 'preferred_common_name'
      @match_field_name              = 'common_name'

      if @type == :common
        @find_match                    = true
      end

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

  private

    def update_results_with_current_data
      return nil unless @results
      @results.each do |result|
        result.merge!(get_current_data_from_taxon_concept_id(result['taxon_concept_id'][0], result))
        repair_missing_match_fields(result)
        if @find_match
          find_best_match(result)
        else
          result.merge!(@best_match_field_name => result[@default_best_match_field_name]) # Show them the preferred name
        end
      end
    end

    def get_current_data_from_taxon_concept_id(id, result)
      begin
        tc = TaxonConcept.find(id)
        return {'title'                 => tc.title(@session_hierarchy),
                'preferred_common_name' => (result["preferred_common_name"] || tc.common_name(@session_hierarchy) || '') }
      # Really, we don't want to save these exceptions, since what good is a search result if the TC is missing?
      # However, tests sometimes create situations where this is possible and not "wrong", (creating TCs is expensive!) so:
      rescue ActiveRecord::RecordNotFound
        return {'title'                 => result['preferred_scientific_name'],
                'preferred_common_name' => (result["preferred_common_name"] || '') }
      end
    end

    def find_best_match(search_result)
      return if search_result[@match_field_name].length <= 1 and search_result[@match_field_name].first.blank? # Nothing to do
      common_names = create_sorted_list_of_intersection_distances(search_result[@match_field_name])
      # if we have only 0s, return the preferred name:
      if common_names.first[:intersection] == 0
        search_result[@best_match_field_name] = search_result[@default_best_match_field_name]
      else
        # if the best matches *include* the preferred name, use that:
        best_matches = best_matched_names(common_names)
        if best_matches.include?(search_result[@default_best_match_field_name].normalize)
          search_result[@best_match_field_name] = search_result[@default_best_match_field_name]
        else # Otherwise, just use the best match:
          search_result[@best_match_field_name] = common_names.first[:name]
        end
      end
    end

    # TODO - I'm not sure these matching methods belong in this class, but I can't think of a better place to put them right
    # now.
    def create_sorted_list_of_intersection_distances(original_common_names)
      common_names = original_common_names.clone
      querystrings = @querystring.normalize.split(' ').to_set
      common_names.map! do |name|
        name_set  = name.normalize.split(' ').to_set
        intersect = name_set.intersection(querystrings) # TODO - make sure querystring members are all downcased.
        {:name => name, :intersection => intersect.size}
      end
      common_names.sort_by {|pair| pair[:intersection] }.reverse 
    end

    def best_matched_names(names)
      best_intersection = names.first[:intersection]
      names.select {|pair| pair[:intersection] == best_intersection}.map {|pair| pair[:name].normalize }
    end

    def repair_missing_match_fields(result)
      result[@match_field_name]      ||= ['']
      result[@best_match_field_name] ||= ''
    end

  end
end

