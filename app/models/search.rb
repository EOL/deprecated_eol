class Search
  attr_accessor :search_string, :searching, :num_results_not_shown, :qualifier,
                :scope, :search_language, :parent_search_log_id, :suggested_searches,
                :search_results, :search_returned, :common_name_results,
                :scientific_name_results, :tag_results, :logged_search_id,
                :scientific_results, :common_results, :search_type,
                :error_message


  def initialize(params, request, current_user, current_agent, execute_search=true)
    @search_string = params[:q]
    @search_type = EOLConvert.get_search_type(params[:search_type])
    @search_language=params[:search_language]
    @parent_search_log_id = params[:search_log_id] || ''    
    @searching=true

    if execute_search # execute a full search
      search(params, request, current_user, current_agent) 
    else # only do the suggested search
      suggested_search
      Search.log({:search_term=>@search_string,:search_type=>@search_type,:parent_search_log_id=>@parent_search_log_id},request,current_user)
    end
  end

  def self.log(params, request, current_user)
    SearchLog.log params, request, current_user if $ENABLE_DATA_LOGGING
  end

  def self.update_log(params)
    return unless $ENABLE_DATA_LOGGING
    logged_search=SearchLog.find_by_id(params[:id])
    logged_search.update_attributes(:taxon_concept_id => params[:taxon_concept_id],:clicked_result_at => Time.now) if logged_search
  end

  def total_search_results
    #@scientific_name_results.length + @common_name_results.length + @tag_results.length
    @scientific_results.length + @common_results.length + @suggested_searches.length + @tag_results.length
  end

  def to_xml(options = {})
    { 'search-string' => @search_string,
      'qualifier'               => @qualifier,
      'scope'                   => @scope,
      'search-language'         => @search_language,
      'suggested-searches'      => @suggested_searches,
      'common-name-results'     => @common_name_results,
      'common-results'          => @common_results,
      'tag-results'             => @tag_results,
      'error-message'           => @error_message,
      'total-search-results'    => @total_search_results,
      'num-results-not-shown'   => @num_results_not_shown,
      'scientific-results'      => @scientific_results,
      'scientific-name-results' => @scientific_name_results
    }.to_xml
  end

  private
  def search(params, request, current_user, current_agent)
    if @search_string =~ /^[^\*]{3,100}\*?$/
      @searching = true
      @num_results_not_shown = 0 # the total number of results that weren't shown because of the user's content level.

      @qualifier       = params[:qualifier]       || 'contains'
      @search_language = params[:search_language] || '*'
      @scope           = params[:scope]           || 'all'

      if @search_type == 'tag'
        tag_search(params,current_user)
      else #default search type is text
        text_search(current_user, current_agent)
      end

      if @search_results || @suggested_searches.length > 0
        @search_returned = true

        @common_name_results     = @search_results[:common]
        @scientific_name_results = @search_results[:scientific]
        @tag_results = @search_results[:tags]

        # Count the number of results that are below our acceptable content level
        if $ALLOW_USER_TO_CHANGE_CONTENT_LEVEL
          (@common_name_results + @scientific_name_results).each do |search_result|
            @num_results_not_shown += 1 if search_result.content_level.to_i < current_user.content_level.to_i
          end

          @tag_results.each do |tag_result|
            @num_results_not_shown += 1 if tag_result[0].content_level.to_i < current_user.content_level.to_i
          end
        end

        # Now filter out only those results that look good to us:
        number_of_stub_page_results = @scientific_name_results.find_all {|result| result['content_level'].to_i < 2 }.size + 
                                      @common_name_results.find_all {|result| result['content_level'].to_i < 2 }.size +
                                      @tag_results.find_all {|result| result[0].content_level < 2}.size

        # I commented this out becuase I'm not sure we're using content_level anymore
        #@scientific_name_results = @scientific_name_results.find_all {|result| result['content_level'].to_i >= current_user.content_level.to_i }
        #@common_name_results     = @common_name_results.find_all     {|result| result['content_level'].to_i >= current_user.content_level.to_i }

        @tag_results = @tag_results.find_all {|results| results[0].content_level >= current_user.content_level.to_i }

        @scientific_results = search_results_by_ids(true, @scientific_name_results, current_user.language, current_user.vetted)
        @common_results = search_results_by_ids(false, @common_name_results, current_user.language, current_user.vetted)

        #log search
        total_number_of_results = @scientific_results.length + @common_results.length + @suggested_searches.length + @tag_results.length

        logged_search = Search.log({:search_term=>@search_string, :search_type=>@search_type, :parent_search_log_id=>@parent_search_log_id, :total_number_of_results=>total_number_of_results, :number_of_common_name_results=>@common_name_results.length, :number_of_scientific_name_results=>@scientific_name_results.length, :number_of_tag_results => @tag_results.length, :number_of_suggested_results=>@suggested_searches.length, :number_of_stub_page_results=> number_of_stub_page_results}, request, current_user)
        @logged_search_id=(logged_search.nil?) ? "" : logged_search.id

        # if we have only one result, go straight to that page
        if total_search_results == 1
          taxon_id = @common_results.empty? ? nil : @common_results[0][:id]
          taxon_id = taxon_id ? taxon_id : (@scientific_results.empty? ? nil : @scientific_results[0][:id])
          taxon_id = taxon_id ? taxon_id : (@tag_results.empty? ? nil: @tag_results[0][0].id)
          taxon_id = taxon_id ? taxon_id : @suggested_searches[0].taxon_id
          Search.update_log({:id=>@logged_search_id,:taxon_concept_id=>taxon_id})
        end
      else # no results, but still log it
        #log search
        Search.log({:search_term=>@search_string, :search_type=>@search_type, :parent_search_log_id=>@parent_search_log_id,:total_number_of_results=>0, :number_of_common_name_results=>0, :number_of_scientific_name_results=>0, :number_of_suggested_results=>0, :number_of_stub_page_results=> 0},request,current_user)
      end
    else
      invalid_search
    end    
  end

  def search_results_by_ids(scientific = true, search_results = [], language = Language.english, vetted = true)

    vern = 0
    if !scientific
      vern = 1
    end
    taxon_concept_ids = []
    taxon_concept_names = []
    search_results.each_with_index do |result, i|
      taxon_concept_ids << result['id']
      taxon_concept_names[result['id'].to_i] = [result['matching_string'], result['matching_italicized_string']]
    end

    if taxon_concept_ids.empty?
      return []
    end

    language ||= Language.english

    vetted_clause = vetted ? " AND do.vetted_id = #{Vetted.trusted.id} " : ""
    if scientific
      results = SpeciesSchemaModel.connection.execute("SELECT tc.id id, tc.vetted_id taxon_vetted_id, tcn.name_id name_id, n.string preferred_scientific_name, n.italicized preferred_scientific_name_italicized, n2.string preferred_common_name, do.object_cache_url thumbnail_cache_url, do.vetted_id thumbnail_vetted_id, he_source.hierarchy_id source_hierarchy_id FROM taxon_concepts tc STRAIGHT_JOIN taxon_concept_names tcn ON (tc.id=tcn.taxon_concept_id) STRAIGHT_JOIN names n ON tcn.name_id=n.id LEFT JOIN (hierarchy_entries he STRAIGHT_JOIN top_images ti ON (he.id=ti.hierarchy_entry_id) STRAIGHT_JOIN data_objects do ON (ti.data_object_id=do.id AND ti.view_order=1 #{vetted_clause})) ON he.taxon_concept_id=tcn.taxon_concept_id LEFT OUTER JOIN (taxon_concept_names tcn2 STRAIGHT_JOIN names n2 ON (tcn2.name_id=n2.id AND tcn2.language_id=#{language.id} AND tcn2.preferred=1)) ON (tcn.taxon_concept_id=tcn2.taxon_concept_id) LEFT JOIN hierarchy_entries he_source ON (tcn.source_hierarchy_entry_id=he_source.id AND tcn.source_hierarchy_entry_id!=0) WHERE tc.id IN (#{taxon_concept_ids.uniq.join(",")}) AND tcn.vern=#{vern} AND tcn.preferred=1 AND tc.supercedure_id=0 GROUP BY tc.id, tcn.name_id, he_source.hierarchy_id ORDER BY n.string ASC").all_hashes
    else
      results = SpeciesSchemaModel.connection.execute("SELECT tc.id id, tc.vetted_id taxon_vetted_id, tcn.name_id name_id, n.string preferred_common_name, n.italicized preferred_common_name_italicized, n2.italicized preferred_scientific_name_italicized, do.object_cache_url thumbnail_cache_url, do.vetted_id thumbnail_vetted_id, he_source.hierarchy_id source_hierarchy_id FROM taxon_concepts tc STRAIGHT_JOIN taxon_concept_names tcn ON (tc.id=tcn.taxon_concept_id) STRAIGHT_JOIN names n ON tcn.name_id=n.id LEFT JOIN (hierarchy_entries he STRAIGHT_JOIN top_images ti ON (he.id=ti.hierarchy_entry_id) STRAIGHT_JOIN data_objects do ON (ti.data_object_id=do.id AND ti.view_order=1 #{vetted_clause})) ON he.taxon_concept_id=tcn.taxon_concept_id LEFT OUTER JOIN (taxon_concept_names tcn2 STRAIGHT_JOIN names n2 ON (tcn2.name_id=n2.id AND tcn2.vern=0 AND tcn2.preferred=1)) ON (tcn.taxon_concept_id=tcn2.taxon_concept_id) LEFT JOIN hierarchy_entries he_source ON (tcn.source_hierarchy_entry_id=he_source.id AND tcn.source_hierarchy_entry_id!=0) WHERE tc.id IN (#{taxon_concept_ids.uniq.join(",")}) AND tcn.vern=#{vern} AND tcn.language_id=#{language.id} AND n2.italicized IS NOT NULL AND tc.supercedure_id=0 GROUP BY tc.id, tcn.name_id, he_source.hierarchy_id ORDER BY n.string ASC").all_hashes
    end

    used_concept_ids = []
    filtered_results = []

    results.each_with_index do |result, i|
      if !used_concept_ids.include?(result['id'].to_i) || result['source_hierarchy_id'].to_i == Hierarchy.default.id
        if result['source_hierarchy_id'].to_i == Hierarchy.default.id
          filtered_results.delete_if { |r| r['id'] == result['id'] }
        end


        result["matching_string"] = taxon_concept_names[result['id'].to_i][0]
        result["matching_italicized_string"] = taxon_concept_names[result['id'].to_i][1]
        filtered_results << result;

        used_concept_ids << result['id'].to_i
      end
    end

    filtered_results = filtered_results.map do |result|
      {
        :id => result["id"],
        :taxon_vetted_id => result["taxon_vetted_id"].to_i,
        :name_id => result["name_id"].to_i,
        :preferred_scientific_name => result["preferred_scientific_name"],
        :preferred_scientific_name_italicized => result["preferred_scientific_name_italicized"],
        :preferred_common_name => result["preferred_common_name"],
        :preferred_common_name_italicized => result["preferred_common_name_italicized"],
        :thumbnail_cache_url => result["thumbnail_cache_url"],
        :thumbnail_vetted_id => result["thumbnail_vetted_id"].to_i,
        :matching_string => taxon_concept_names[result["id"].to_i][0],
        :matching_italicized_string => taxon_concept_names[result["id"].to_i][1]
      }
    end

    sorted_results = filtered_results.sort_by { |result| result[:matching_string].firstcap }

    return sorted_results[0..200]
  end

  def tag_search(params,current_user=nil)
    @suggested_searches = [] #TODO: implement suggested search terms for tags
    if @search_string
      split_tags = @search_string.split(/[,\s]/).map(&:strip).select {|t| !t.blank?}  
      tags = split_tags.inject([]) do |all,this|
        if this.include?':'
          key, value = this.split(':')
        else
          key, value = this.split('=')
        end
        if key && value
          all << [DataObjectTag[key, value]]
        else
          #key is actually a value
          #RAILS_DEFAULT_LOGGER.warn { "all += #{key}:#{ DataObjectTag[key].inspect }" }
          all << DataObjectTag.find(:all, :conditions => ["value = ?", key] )
        end
      end
      tags = tags.compact.uniq

      options = (params['selected-clade-id'] && params['selected-clade-id'].to_i > 0) ? { :clade => params['selected-clade-id'].to_i } : {}
      user_id=current_user.id unless current_user.blank?
      user_id=params['user_id'] if user_id.blank? && !params['user_id'].blank?
      options.merge!(user_id.blank? ? {:user_id => nil} : {:user_id => user_id})
      data_objects = DataObject.search_by_tags tags, options
    else
      data_objects = []
    end        
    results = []
    user = options[:user_id] ? User.find(options[:user_id]) : nil
    vetted_only = user && user.vetted
    data_objects.each do |data_object|
      if !vetted_only || data_object.vetted_id == Vetted.trusted.id
        data_object.taxon_concepts.each do |taxon_concept|
          results << [taxon_concept,data_object] if (!vetted_only || taxon_concept.vetted_id == Vetted.trusted.id) && taxon_concept.published==1
        end
      end
    end

    @search_results = {:common => [], :scientific => [], :errors => [], :tags => results}    
  end

  def text_search(current_user, current_agent)
    suggested_search
    @search_results = TaxonConcept.quick_search(@search_string,
                                          :user=>current_user,
                                          :agent=>current_agent,
                                          :qualifier=>@qualifier,
                                          :scope=>@scope,
                                          :search_language=>@search_language)
    @search_results[:tags] = []
  end

  # look for user's search term in suggested searches:  
  def suggested_search
    @suggested_searches = SearchSuggestion.find_all_by_term_and_active(@search_string,true,:order=>'sort_order') if @search_type == 'text'
  end

  def invalid_search
    @searching = false
    @qualifier       = "contains"
    @scope           = "all"    
    @search_language = "*"  
    @error_message = "Your search term was invalid."  
  end
end
