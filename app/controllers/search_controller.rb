class SearchController < ApplicationController
  layout 'v2/search'

  @@results_per_page = 25

  def index
    params[:sort_by] ||= 'score'
    params[:type] ||= ['all']
    params[:type] = ['all'] if params[:type].include?('all')
    params[:type] = ['taxon_concept'] if params[:mobile_search] # Mobile search is limited to taxa for now
    @sort_by = params[:sort_by]
    @params_type = params[:type]
    @params_type = ['all'] if @params_type.include?('all')
    @params_type.map!{ |t| t.camelize }
    @querystring = params[:q] || params[:id] || params[:mobile_search]

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

    @page_title  = I18n.t(:search_by_term_page_title, :term => @querystring)
    if @querystring.blank? || bad_query
      @all_results = empty_paginated_set
      @facets = {}
    else
      search_response = EOL::Solr::SiteSearch.search_with_pagination(@querystring, params.merge({ :per_page => @@results_per_page }))
      @all_results = search_response[:results]
      @facets = (@wildcard_search) ? {} : EOL::Solr::SiteSearch.get_facet_counts(@querystring)
      @suggestions = search_response[:suggestions]
      log_search(request) unless params[:mobile_search]
      current_user.log_activity(:text_search_on, :value => params[:q])
      if params[:mobile_search] && !mobile_disabled_by_session?
        if @all_results.length == 1 && @all_results.total_entries == 1
          redirect_to mobile_taxon_path(@all_results.first["resource_id"]), :status => :moved_permanently
        else
          render :template => 'mobile/search/index', :layout => "v2/mobile/application"
        end
      elsif params[:show_all].blank? && @all_results.length == 1 && @all_results.total_entries == 1
        redirect_to_page(@all_results.first, :total_results => 1, :params => params)
      elsif params[:show_all].blank? && @params_type[0].downcase == 'all' && @all_results.total_entries > 1 && @all_results.length > 1 &&
        superior_result = pick_superior_result(@all_results)
        redirect_to_page(superior_result, :total_results => @all_results.total_entries, :params => params)
      end
    end
    params.delete(:type) if params[:type] == ['all']
    params.delete(:sort_by) if params[:sort_by] == 'score'

    @rel_canonical_href = search_q_url({:q => @querystring, :show_all => true,
      :page => rel_canonical_href_page_number(@all_results)})
    @rel_prev_href = rel_prev_href_params(@all_results) ? search_q_url(@rel_prev_href_params) : nil
    @rel_next_href = rel_next_href_params(@all_results) ? search_q_url(@rel_next_href_params) : nil
  end

  # there are various object types which can be the only result. This method handles redirecting to all of them
  def redirect_to_page(result, options={})
    modified_params = options[:params].dup
    modified_params.delete(:type) if modified_params[:type] == ['all']
    modified_params.delete(:sort_by) if modified_params[:sort_by] == 'score'
    modified_params.delete_if{ |k, v| ![ :sort_by, :type ].include?(k) }
    modified_params[:q] = @querystring
    if options[:total_results] > 1
      flash[:notice] = I18n.t(:flash_notice_redirected_from_search_html_more_results, :search_string => @querystring, :more_results_url => search_path(nil, modified_params.merge({ :show_all => true })))
    elsif options[:total_results] == 1
      flash[:notice] = I18n.t(:flash_notice_redirected_from_search_html, :search_string => @querystring, :more_results_url => search_path(nil, modified_params.merge({ :show_all => true })))
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
    end
  end

  def empty_paginated_set
    [].paginate(:page => 1, :per_page => @@results_per_page, :total_entries => 0)
  end

  # Add an entry to the database desrcibing the fruitfullness of this search.
  def log_search(req)
    logged_search = SearchLog.log(
      { :search_term => @querystring,
        :search_type => @params_type.join(";"),
        :parent_search_log_id => nil,
        :total_number_of_results => @all_results.length },
      req,
      current_user)
    @logged_search_id = logged_search.nil? ? '' : logged_search.id
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
end
