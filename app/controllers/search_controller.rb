class SearchController < ApplicationController

  skip_before_filter :original_request_params, :global_warning, :set_locale, :check_user_agreed_with_terms,
    only: :autocomplete_taxon
  after_filter :set_cache_headers, only: :autocomplete_taxon

  layout 'search'

  @@results_per_page = 25

  helper_method :search_data?

  # NOTE - this is confusing, but it wasn't worth renaming the variable: "all_results" does not include traitbank results.
  # @attributes contains the traitbank results. If you really want "all" results, you need to combine the two.
  def index
    params[:sort_by] ||= 'score'
    params[:type] ||= ['all']
    params[:type] = ['taxon_concept'] if params[:mobile_search] # Mobile search is limited to taxa for now
    @all_params = []
    [:taxon_concept, :image, :video, :sound, :text, :data, :link, :user, :community ,:collection].each do |keyword|
      @all_params << [I18n.t("#{keyword}_search_keyword", count: 1),I18n.t("#{keyword}_search_keyword", count: 123),keyword]
    end    
    @sort_by = params[:sort_by]
    @params_type = params[:type]
    @params_type = ['all'] if @params_type.map(&:downcase).include?('all')
    @params_type.map!{ |t| t.camelize }
    @querystring = params[:q] || params[:id] || params[:mobile_search]
    params[:id] = nil
    params[:q] = @querystring

    @attributes = []
    @attributes = KnownUri.by_name(@querystring) if search_data?

    if request.format == Mime::XML
      return redirect_to controller: "api", action: "search", id: @querystring
    end

    if @querystring == I18n.t(:search_placeholder) || @querystring == I18n.t(:must_provide_search_term_error)
      flash[:error] = I18n.t(:must_provide_search_term_error)
      redirect_to root_path
    end

    if @querystring == '*' || @querystring == '%'
      @wildcard_search = true
      if params[:type].size != 1 || !EOL::Solr::SiteSearch.types_to_show_all.include?(params[:type].first)
        bad_query = true
      end
    end

    params[:exact] = false
    # if the querystring is a double-quoted string, then interpret this as an exact search
    if @querystring =~ /^".*"$/
      @querystring = @querystring[1...-1]
      params[:exact] = true
    end

    @page_title  = I18n.t(:search_by_term_page_title, term: @querystring)
    if @querystring.blank? || bad_query
      @all_results = empty_paginated_set
      @facets = {}
    else
      query_array = (@querystring.downcase.gsub(/\s+/m, ' ').strip.split(" "))
      query_reserved_words = (query_array & @all_params.map{|key| key[0]}) + (query_array & @all_params.map{|key| key[1]})
      if query_reserved_words.any?
        @params_type += query_reserved_words.map{|word| @all_params.select{|param| param[0] == word || param[1] == word}.first[2].to_s.camelize}
        @params_type -= ['All']
        query_array.reject! {|t| (@all_params.map{|key| key[0]}).include?(t) || (@all_params.map{|key| key[1]}).include?(t)}
        @querystring = query_array.join(" ")
        params[:type] = @params_type
      end
      search_response = EOL::Solr::SiteSearch.search_with_pagination(@querystring, params.merge({ per_page: @@results_per_page, language_id: current_language.id }))
      if $STATSD
        $STATSD.increment 'all_searches'
        # $STATSD.increment "searches.#{@querystring}"
      end
      @all_results = search_response[:results]
      @facets = (@wildcard_search) ? {} : EOL::Solr::SiteSearch.get_facet_counts(@querystring)
      @suggestions = search_response[:suggestions]
      log_search(request) unless params[:mobile_search]
      current_user.log_activity(:text_search_on, value: params[:q])
      # TODO - there is a weird, rare border case where total_entries == 1 and #length == 0. Not sure what causes it, but we should handle that
      # case here, probably by re-submitting the search (because, at least in the case I saw, the next load of the page was fine).
      if params[:show_all].blank? && @all_results.length == 1 && @all_results.total_entries == 1
        redirect_to_page(@all_results.first, total_results: 1, params: params)
      elsif params[:show_all].blank? && @params_type[0] == 'All' && @all_results.total_entries > 1 && @all_results.length > 1 &&
        superior_result = pick_superior_result(@all_results)
        redirect_to_page(superior_result, total_results: @all_results.total_entries, params: params)
      end
    end
    params.delete(:type) if params[:type] == ['all']
    params.delete(:sort_by) if params[:sort_by] == 'score'

    set_canonical_urls(for: {q: @querystring, show_all: true}, paginated: @all_results,
                       url_method: :search_url)
    @combined_results_count = @all_results.total_entries + @attributes.count
  end

  # there are various object types which can be the only result. This method handles redirecting to all of them
  def redirect_to_page(result, options={})
    modified_params = options[:params].dup
    modified_params.delete(:type) if modified_params[:type] == ['all']
    modified_params.delete(:sort_by) if modified_params[:sort_by] == 'score'
    modified_params.delete_if{ |k, v| ![ 'sort_by', 'type' ].include?(k) }
    modified_params[:q] = @querystring
    if options[:total_results] > 1
      flash[:notice] = I18n.t(:flash_notice_redirected_from_search_html_more_results, search_string: @querystring, more_results_url: search_path(modified_params.merge({ show_all: true })))
    elsif options[:total_results] == 1
      flash[:notice] = I18n.t(:flash_notice_redirected_from_search_html, search_string: @querystring, more_results_url: search_path(modified_params.merge({ show_all: true })))
    end
    result_instance = result['instance']
    if result_instance.class == Collection
      redirect_to collection_path(result_instance.id)
    elsif result_instance.class == Community
      redirect_to community_path(result_instance.id)
    elsif result_instance.class == DataObject
      redirect_to data_object_path(result_instance.id)
    elsif result_instance.class == User
      redirect_to user_path(result_instance.id)
    elsif result_instance.class == TaxonConcept
      redirect_to taxon_overview_path(result_instance.id)
    elsif result_instance.class == ContentPage
      redirect_to cms_page_path(result_instance.id)
    end
  end

  def empty_paginated_set
    [].paginate(page: 1, per_page: @@results_per_page, total_entries: 0)
  end

  # Add an entry to the database desrcibing the fruitfullness of this search.
  def log_search(req)
    logged_search = SearchLog.log(
      { search_term: @querystring,
        search_type: @params_type.join(";"),
        parent_search_log_id: nil,
        total_number_of_results: @all_results.length },
      req,
      current_user)
    @logged_search_id = logged_search.nil? ? '' : logged_search.id
  end

  def autocomplete_taxon
    @from_site_search = !! params[:site_search]
    @querystring = params[:term].strip
    # NOTE - the regex here looks for ANY WORD in the string which is shorter than three characters. Thus "Aba c" will NOT work.
    # TODO - this is perhaps not the best way to handle it. I believe we can't do multiword search yet, so that makes sense, but we could just split the
    # term here and exclude any pieces that are too short and at least the longer names will go through and we'll get results... :\
    if @querystring.blank? || @querystring.length < 3 || @querystring.match(/(^|[^a-z])[a-z]{0,2}([^a-z]|$)/i)
      json = {}
    else
      res = EOL::Solr::SiteSearch.taxon_search(@querystring, language: current_language)
      taxa = res[:taxa]
      result_title = res[:result_title]
      json = taxa.each_with_index.map do |result, index|
        { id: result['instance'].id,
          value: result['instance'].title_canonical,
          label: render_to_string(
          partial: 'shared/item_summary_taxon_autocomplete',
          locals: { item: result['instance'], search_result: result, result_title: result_title, index: index } )
        }
      end.delete_if { |r| r[:value].blank? }
    end
    render json: json
  end

  private

  # if the first returned taxon has a score greater than 3, and
  def pick_superior_result(all_results)
    minimum_score = 3
    superior_multiple = 4
    first_taxon = nil

    all_results.each do |r|
      break if first_taxon.nil? && r['score'] < minimum_score
      if first_taxon.nil? && r['resource_type'].include?('TaxonConcept') && r['score'] > minimum_score
        first_taxon = r
      elsif first_taxon && r['resource_type'].include?('TaxonConcept')
        if first_taxon['score'] > (r['score'] * superior_multiple)
          return first_taxon
        else
          # the second taxon isn't far worse than the first, so break
          first_taxon = nil
          break
        end
      end
    end
    first_taxon
  end

  def set_cache_headers
    return if response.status != 200
    # 604,800 seconds == 1 week
    expires_in 604800, public: true
  end

  def search_data?
    return false if @querystring.blank?
    return true if @params_type.include?('All') || @params_type.include?('Data')
    false
  end

end
