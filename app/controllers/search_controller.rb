class SearchController < ApplicationController
  layout 'v2/search'
  
  @@results_per_page = 10
  
  def index
    @sort_by = params[:sort_by] || 'newest'
    @params_type = params[:type] || ['all']
    @params_type = ['all'] if @params_type.include?('all')
    @params_type.map!{ |t| t.camelize }
    @querystring = params[:q] || params[:id]
    params[:per_page] = @@results_per_page
    @page_title  = I18n.t(:search_by_term_page_title, :term => @querystring)
    if @querystring.blank?
      @all_results = empty_paginated_set
    else
      search_response = EOL::Solr::SiteSearch.search_with_pagination(@querystring, params)
      @all_results = search_response[:results]
      @facets = search_response[:facets]
      log_search(request)
      current_user.log_activity(:text_search_on, :value => params[:q])
      if @all_results.length == 1 && params[:page].to_i < 2
        redirect_to_taxa_page(@all_results)
      end
    end
  end
  
  def redirect_to_taxa_page(result_set)
    flash[:notice] = I18n.t(:flash_notice_redirected_from_search_html, :search_string => @querystring)
    redirect_to taxon_overview_path(result_set.first['resource_id'])
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
end
