#encoding: utf-8

class DataSearchController < ApplicationController

  include ActionView::Helpers::TextHelper
  include DataSearchHelper
  before_filter :restrict_to_data_viewers
  before_filter :allow_login_then_submit, only: :download

  layout 'data_search'
  # TODO - optionally but preferentially pass in a known_uri_id (when we have it), to avoid the ugly URL
  def index
    @page_title = I18n.t('data_search.page_title')
    prepare_search_parameters(params)
    prepare_attribute_options
    prepare_suggested_searches
    respond_to do |format|
      format.html do
        if @taxon_concept && !TaxonData.is_clade_searchable?(@taxon_concept)
          flash.now[:notice] = I18n.t('data_search.notice.clade_too_big',
            taxon_name: @taxon_concept.title_canonical_italicized.html_safe,
            contactus_tech_path: contact_us_path(subject: 'Tech')).html_safe
        elsif @clade_has_no_data
          flash.now[:notice] = I18n.t('data_search.notice.clade_has_no_data',
            taxon_name: @taxon_concept.title_canonical_italicized.html_safe,
            contribute_path: cms_page_path('contribute', anchor: 'data')).html_safe
        end
        t = Time.now
        @results = TaxonData.search(@search_options.merge(page: @page, per_page: 30)) 
        if @results
          @counts_of_values_from_search = TaxonData.counts_of_values_from_search(@search_options.merge(page: @page, per_page: 30))
          log_data_search(time_in_seconds: Time.now - t)
        end
      end
    end
  end

  def update_attributes
    prepare_attribute_options
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def download
    if session[:submitted_data]
      search_params = session.delete(:submitted_data)
    else
      search_params = params.dup
    end
    prepare_search_parameters(search_params)
    total_results = EOL::Sparql.connection.query(EOL::Sparql::SearchQueryBuilder.prepare_search_query(@search_options.merge(only_count: true))).first[:count].to_i
    #create all download files
    no_of_files = (total_results.to_f / DataSearchFile::LIMIT).ceil
    for count in 1..no_of_files
      df = create_data_search_file
      df.update_attributes(file_number: count)
      Resque.enqueue(DataFileMaker, data_file_id: df.id)
    end
    flash[:notice] = I18n.t(:file_download_pending, link: user_data_downloads_path(current_user.id))
    redirect_to user_data_downloads_path(current_user.id)
  end

  private

  
  def create_data_search_file
    file = DataSearchFile.create!(@data_search_file_options)
    unless @required_equivalent_attributes.blank?
      @required_equivalent_attributes.each do |eq|
        DataSearchFileEquivalent.create(data_search_file_id: file.id, uri_id: eq.to_i, is_attribute: true)
      end
    end
    unless @required_equivalent_values.blank?
      @required_equivalent_values.each do |eq|
        DataSearchFileEquivalent.create(data_search_file_id: file.id, uri_id: eq.to_i, is_attribute: false)
      end
    end
    file
  end
  # TODO - this should be In the DB with an admin/master curator UI behind it. I would also add a "comment" to that model, when
  # we build it, which would populate a flash message after the search is run; that would allow things like "notice how this
  # search specifies a URI as the query" and the like, calling out specific features of each search.
  #
  # That said, we will have to consider how to deal with I18n, both for the "comment" and for the label.
  def prepare_suggested_searches
    @suggested_searches = CuratorsSuggestedSearch.suggested_searches(current_language) 
  end

  # Add an entry to the database recording the number of results and time of search operation
  def log_data_search(options = {})
    # We are logging when there is only a TaxonConceptID - that will occur if a users clicks on a search
    # link from the data tab on a taxon page. In that case, a search is NOT performed, but we are
    # creating a log to capture the time it takes to populate the attribute list.
    # For every log which has an attribute, a search WILL have been performed
    if params[:attribute] || params[:taxon_concept_id]
      DataSearchLog.create(
        @data_search_file_options.merge({
          clade_was_ignored: (@taxon_concept && ! TaxonData.is_clade_searchable?(@taxon_concept)) ? true : false,
          user_id: ( logged_in? ? current_user.id : nil ),
          number_of_results: @results.total_entries,
          time_in_seconds: options[:time_in_seconds],
          ip_address: request.remote_ip
        })
      )
    end
  end


end
