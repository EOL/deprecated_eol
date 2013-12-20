class DataSearchController < ApplicationController

  before_filter :restrict_to_data_viewers
  before_filter :allow_login_then_submit, only: :download

  layout 'v2/data_search'

  # TODO - pass in a known_uri_id when we have it, to avoid the ugly URL
  def index
    prepare_search_parameters(params)
    prepare_attribute_select_options
    respond_to do |format|
      format.html do
        @results = TaxonData.search(@search_options.merge(page: @page, per_page: 30))
      end
    end
  end

  def download
    if session[:submitted_data]
      search_params = session.delete(:submitted_data)
    else
      search_params = params.dup
    end
    prepare_search_parameters(search_params)
    df = create_data_search_file
    flash[:notice] = I18n.t(:file_download_pending, link: user_saved_searches_path(current_user.id))
    Resque.enqueue(DataFileMaker, data_file_id: df.id)
    redirect_to user_saved_searches_path(current_user.id)
  end

  private

  def create_data_search_file
    DataSearchFile.create!(
      q: @querystring, uri: @attribute, from: @from, to: @to,
      sort: @sort, known_uri: @attribute_known_uri, language: current_language,
      user: current_user
    )
  end

  def prepare_search_parameters(options)
    @hide_global_search = true
    @querystring = options[:q]
    @attribute = options[:attribute]
    @sort = options[:sort]
    @page = options[:page] || 1
    @taxon_concept = TaxonConcept.find_by_id(options[:taxon_concept_id])
    @attribute = nil unless EOL::Sparql.connection.all_measurement_type_uris.include?(@attribute)
    @attribute_known_uri = KnownUri.find_by_uri(@attribute)
    @from, @to = nil, nil
    # we must at least have an attribute to perform a Virtuoso query, otherwise it would be too slow
    unless @attribute.blank?
      if @querystring && matches = @querystring.match(/^([^ ]+) to ([^ ]+)$/)
        from = matches[1]
        to = matches[2]
        if from.is_numeric? && to.is_numeric?
          @from, @to = [ from.to_f, to.to_f ].sort
        end
      end
    end
    @search_options = { querystring: @querystring, attribute: @attribute, from: @from, to: @to,
      sort: @sort, language: current_language, taxon_concept: @taxon_concept }
  end

  def prepare_attribute_select_options
    @select_options = { "-- " + I18n.t('activerecord.attributes.user_added_data.predicate') + " --" => nil }
    if @taxon_concept
      measurment_uris = TaxonData.new(@taxon_concept, current_user).ranges_of_values.collect{ |r| r[:attribute] }
    else
      measurment_uris = EOL::Sparql.connection.all_measurement_type_known_uris
    end
    @select_options = @select_options.merge(Hash[ measurment_uris.collect do |uri|
      label = uri.is_a?(KnownUri) ? uri.name : EOL::Sparql.uri_to_readable_label(uri)
      label.nil? ? nil : [ label.firstcap, uri.is_a?(KnownUri) ? uri.uri : uri ]
    end.compact.sort_by{ |k,v| k.nil? ? '' : k } ] )
  end

end
