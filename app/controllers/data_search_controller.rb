#encoding: utf-8

class DataSearchController < ApplicationController

  before_filter :restrict_to_data_viewers
  before_filter :allow_login_then_submit, only: :download

  layout 'v2/data_search'

  # TODO - optionally but preferentially pass in a known_uri_id (when we have it), to avoid the ugly URL
  def index
    prepare_search_parameters(params)
    prepare_suggested_searches

    unless @taxon_concept.blank? || TaxonData.clade_is_searchable?(@taxon_concept)
      flash.now[:notice] = I18n.t('data_search.notice.clade_too_big',
        taxon_name: @taxon_concept.title_canonical_italicized.html_safe).html_safe
    end
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
      q: @querystring, uri: @attribute, from: @min_value, to: @max_value,
      sort: @sort, known_uri: @attribute_known_uri, language: current_language,
      user: current_user, taxon_concept_id: (@taxon_concept ? @taxon_concept.id : nil),
      unit_uri: @unit
    )
  end

  def prepare_search_parameters(options)
    @hide_global_search = true
    @querystring = options[:q]
    @attribute = options[:attribute]
    @attribute_missing = @attribute.nil? && params.has_key?(:attribute) 
    @sort = (options[:sort] && [ 'asc', 'desc' ].include?(options[:sort])) ? options[:sort] : 'desc'
    @unit = options[:unit].blank? ? nil : options[:unit]
    @min_value = (options[:min] && options[:min].is_numeric?) ? options[:min].to_f : nil
    @max_value = (options[:max] && options[:max].is_numeric?) ? options[:max].to_f : nil
    @page = options[:page] || 1
    @taxon_concept = TaxonConcept.find_by_id(options[:taxon_concept_id])
    # Look up attribute based on query
    unless @querystring.blank? || EOL::Sparql.connection.all_measurement_type_uris.include?(@attribute)
      @attribute_known_uri = KnownUri.by_name(@querystring)
      @attribute = @attribute_known_uri.uri if @attribute_known_uri
      @querystring = options[:q] = ''
    else
      @attribute_known_uri = KnownUri.find_by_uri(@attribute)
    end
    if @attribute_known_uri && ! @attribute_known_uri.units_for_form_select.empty?
      @units_for_select = @attribute_known_uri.units_for_form_select
    else
      @units_for_select = KnownUri.default_units_for_form_select
    end
    @search_options = { querystring: @querystring, attribute: @attribute, min_value: @min_value, max_value: @max_value,
      unit: @unit, sort: @sort, language: current_language, taxon_concept: @taxon_concept }
  end

  def prepare_suggested_searches
    @suggested_searches = [
      { label_key: 'search_suggestion_whale_mass',
        params: {
          utf8: '✓',
          sort: 'desc',
          min: 10000,
          taxon_concept_id: 7649,
          attribute: 'http://eol.org/schema/terms/pantheria_5-1_AdultBodyMass_g',
          unit: 'http://purl.obolibrary.org/obo/UO_0000009' }},
      { label_key: 'search_suggestion_cavity_nests',
        params: {
          q: 'cavity',
          attribute: 'http://eol.org/schema/terms/NestType' }},
      { label_key: 'search_suggestion_diatom_shape',
        params: {
          attribute: 'http://eol.org/schema/terms/DiatomShape' }},
      { label_key: 'search_suggestion_images_of_dinophyceae',
        params: {
          taxon_concept_id: 4758,
          attribute: 'http://eol.org/schema/terms/NumberImagesInEOL' }},
      { label_key: 'search_suggestion_wingspan',
        params: {
          sort: 'asc',
          taxon_concept_id: 8021,
          attribute: 'http://www.owl-ontologies.com/unnamed.owl#Wingspan' }}
    ]
  end

end
