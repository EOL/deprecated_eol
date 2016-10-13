class KnownUrisController < ApplicationController

  AUTOCOMPLETE_ACTIONS = [ :autocomplete_known_uri_search, :autocomplete_known_uri_units, :autocomplete_known_uri_metadata,
                           :autocomplete_known_uri_predicates, :autocomplete_known_uri_values ]

  before_filter :set_page_title, except: AUTOCOMPLETE_ACTIONS
  before_filter :restrict_to_admins_and_master_curators, except: AUTOCOMPLETE_ACTIONS
  before_filter :set_stats_filter_options, only: [ :index, :show_stats ]
  skip_before_filter :original_request_params, :global_warning, :set_locale, :check_user_agreed_with_terms,
    only: AUTOCOMPLETE_ACTIONS
  after_filter :clear_cache, only: [ :create, :update, :destroy, :import_ontology ]

  layout 'basic'

  def index
    @known_uris = KnownUri.show_in_gui.
      includes([:uri_type, :toc_items,
        known_uri_relationships_as_subject: :to_known_uri])
    if params[:category_id]
      @known_uris = @known_uris.where(known_uris_toc_items: { toc_item_id: params[:category_id] }) if params[:category_id]
    else
      @uri_type ||= params.has_key?(:uri_type_id) ? UriType.find(params[:uri_type_id]) : UriType.measurement
      @known_uris = @known_uris.where(uri_type_id: @uri_type.id)
    end
    if params[:name]
      @known_uris = @known_uris.where("name LIKE \"%#{params[:name]}%\"")
    end
    @known_uris = @known_uris.paginate(page: params[:page],
      order: 'known_uris.position', per_page: 500)
    respond_to do |format|
      format.html do
      end
      format.js do
        @category = TocItem.find(params[:category_id])
      end
    end
  end

  def show_stats
    if params[:ajax].blank?
      redirect_to known_uris_path(stats_filter: params[:stats_filter])
    else
      params.delete(:ajax)
      render(partial: 'stats_report')
      return
    end
  end

  def import_ontology
    @ontology_uri = params[:ontology_uri]
    if @ontology_uri.blank?
      redirect_to known_uris_path
    else
      @terms = SchemaTermParser.parse_terms_from(@ontology_uri)
      @ingested_terms = []
      @existing_known_uris = KnownUri.by_uris(@terms.map { |uri, metadata| uri })
      if params[:importing]
        attribute_types_selected = {}
        attribute_mappings = { 'rdfs:label' => 'name' }
        error = false
        SchemaTermParser.attribute_uris.each do |uri|
          if params.has_key?(uri.to_s)
            if params[uri.to_s].blank?
              error = flash[:error] = I18n.t('known_uris.please_select_field_types')
            elsif attribute_types_selected[params[uri.to_s]]
              error = flash[:error] = I18n.t('known_uris.more_than_one_field_mapped_to_type', type: params[uri.to_s])
            elsif params[uri.to_s] != 'none'
              attribute_types_selected[params[uri.to_s]] = uri
              attribute_mappings[uri] = params[uri.to_s]
            end
          end
        end
        if params[:selected_uris].blank?
          error = flash[:error] = I18n.t('known_uris.please_select_uris_to_import')
        end
        if !error
          import_terms_from_ontology(attribute_mappings)
          clear_cache
          flash[:notice] = I18n.t('known_uris.import_successful')
          redirect_to known_uris_path
        end
      end
    end
  end

  def categories
    @recently_used = KnownUri.by_uris(session[:rec_uris]) if session[:rec_uris]
    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

  def show
    @known_uri = KnownUri.find(params[:id])
  end

  def new
    @known_uri = KnownUri.new
  end

  def create

    allowed_units_target_ids = params[:known_uri].delete(:allowed_units_target_ids)
    @known_uri = KnownUri.new(params[:known_uri])
    if @known_uri.save
      if allowed_units_target_ids
        allowed_units_target_ids.each do |target_known_uri_id|
          KnownUriRelationship.create(to_known_uri: KnownUri.find(target_known_uri_id), from_known_uri: @known_uri,
                                      relationship_uri: KnownUriRelationship::ALLOWED_UNIT_URI)
        end
      end
      flash[:notice] = I18n.t(:known_uri_created)
      redirect_back_or_default(known_uris_path(uri_type_id: @known_uri.uri_type_id))
    else
      render action: 'new'
    end
  end

  def edit
    @known_uri = KnownUri.find(params[:id], include: [ :toc_items, :known_uri_relationships_as_subject ] )
  end

  def sort
    last_position = nil
    @known_uri = KnownUri.find(params['moved_id'].sub('known_uri_', ''))
    if params['known_uris']
      position_in_results = params['known_uris'].index(params['moved_id'])
      if position_in_results == params['known_uris'].length - 1
        # the URI was moved to the last position. It will be 1 higher than the previous last,
        # and we update anything with a position higher than that (could be a URI from a different page or type)
        previous_element = KnownUri.find(params['known_uris'][-2].sub('known_uri_', ''))
        @known_uri.position = previous_element.position + 1
        KnownUri.update_all('position = position + 1', "position >= #{previous_element.position + 1}")
        @known_uri.save
      else
        # the URI was moved to something other than last place. It will assume the position of the
        # URI just below it, and anything with a position higher than that is increased by 1
        next_element = KnownUri.find(params['known_uris'][position_in_results + 1].sub('known_uri_', ''))
        @known_uri.position = next_element.position
        KnownUri.update_all('position = position + 1', "position >= #{next_element.position}")
        @known_uri.save
      end
    elsif params['to'] == 'top'
      @to = :top
      @known_uri.move_to_top
    elsif params['to'] == 'bottom'
      @to = :bottom
      @known_uri.move_to_bottom
    else
      raise(InvalidArgumentsError)
    end
    respond_to do |format|
      format.js { }
    end
  end

  def unhide # awful name because 'show' is--DUH--reserved for Rails.
    @known_uri = KnownUri.find(params[:id])
    if current_user.is_admin?
      @known_uri.show(current_user)
    end
    redirect_to action: 'index', uri_type_id: @known_uri.uri_type_id
  end

  def hide
    @known_uri = KnownUri.find(params[:id])
    if current_user.is_admin?
      @known_uri.hide(current_user)
    end
    redirect_to action: 'index', uri_type_id: @known_uri.uri_type_id
  end

  def update
    @known_uri = KnownUri.find(params[:id])
    params[:known_uri][:toc_item_ids] ||=nil #This fixes a problem where params doesn't add this attribute to update it when unchecking all TocItem boxes
    if @known_uri.update_attributes(params[:known_uri])
      flash[:notice] = I18n.t(:known_uri_updated)
      redirect_back_or_default(known_uris_path(uri_type_id: @known_uri.uri_type_id))
    else
      render action: "edit"
    end
  end

  def destroy
    @known_uri = KnownUri.find(params[:id])
    @known_uri.destroy
    redirect_to known_uris_path
  end

  def set_as_exemplar_for_same_as
    @known_uri = KnownUri.find(params[:id])
    @known_uri.set_as_exemplar_for_same_as_group
    redirect_to request.referer
  end

  # search for any URI by name or URI
  def autocomplete_known_uri_search
    @known_uris = params[:term].blank? ? [] : search_known_uris_by_name_or_uri(params[:term])
    render_autocomplete_results
  end

  # search for primary measurement predicates. This won't be called unless there
  # is a term, so do a basic search and filter on measurement type
  def autocomplete_known_uri_predicates
    @known_uris = search_known_uris_by_name_or_uri(params[:term])
    @known_uris.delete_if{ |ku| ku.uri_type_id != UriType.measurement.id || ! EOL::Sparql.connection.all_measurement_type_known_uris.include?(ku) }
    render_autocomplete_results
  end

  # search for unit URIs. If the term is empty and given a predicate, use the
  # visible specified units as a pick list. If given a term, search for any
  # KnownUri which is a unit of measure value URI
  def autocomplete_known_uri_units
    lookup_predicate
    if params[:term].blank? || params[:term].strip.blank?
      @known_uris = @predicate ? @predicate.units_for_form_select : []
      if @known_uris.blank?
        @known_uris = KnownUri.default_units_for_form_select
      end
    else
      @known_uris = search_known_uris_by_name_or_uri(params[:term])
      allowed_values = KnownUri.unit_of_measure.allowed_values
      @known_uris.delete_if{ |ku| ! allowed_values.include?(ku) }
    end
    render_autocomplete_results
  end

  # search for metadata URIs. If the term is empty then use all visible metadata URIs
  # as a pick list. The :predicate_known_uri_id parameter here refers to the primary measurement.
  # If that primary measurement has specified units, then remove UnitOfMeasure from the pick
  # list as it should already be shown as a separate field
  def autocomplete_known_uri_metadata
    lookup_predicate
    if params[:term].strip.blank?
      @known_uris = KnownUri.metadata.select{ |ku| ku.visible? }
    else
      @known_uris = search_known_uris_by_name_or_uri(params[:term])
      @known_uris.delete_if{ |ku| ku.uri_type_id != UriType.metadata.id }
    end
    if @predicate && @predicate.has_units?
      @known_uris.delete(KnownUri.unit_of_measure)
    end
    render_autocomplete_results
  end

  # search for value URIs, but only given a predicate. If the term is empty then use all visible
  # specified values as a pick list. Only autocomplete within values specified for the predicate
  def autocomplete_known_uri_values
    lookup_predicate
    if params[:term].blank? || params[:term].strip.blank?
      if @predicate && @predicate.has_values?
        @known_uris = @predicate.allowed_values.select{ |ku| ku.visible? }
      else
        @known_uris = []
      end
    else
      @known_uris = search_known_uris_by_name_or_uri(params[:term])
      if @predicate
        @known_uris.delete_if{ |ku| ! @predicate.allowed_values.include?(ku) }
      else
        @known_uris.delete_if{ |ku| ! ku.value? }
      end
    end
    render_autocomplete_results
  end

  private

  def render_autocomplete_results
    @known_uris ||= []
    @known_uris.uniq!
    @known_uris.sort!
    @known_uris = @known_uris[0..20]
    KnownUri.preload_associations(@known_uris, [ :uri_type, { known_uri_relationships_as_subject: :to_known_uri } ])
    render json: @known_uris.compact.uniq.collect{ |k| { id: k.id, value: k.name, uri: k.uri,
      label: "#{k.name} (#{k.uri})", uri_type: k.has_units? ? 'measurement' : nil,
      has_values: k.has_values? ? '1' : nil }}.to_json
  end

  def set_page_title
    @page_title = I18n.t(:known_uris_page_title)
  end

  def set_stats_filter_options
    @stats_filter_options = [
      [I18n.t('known_uris.unrecognized_measurement_types'), 'measurement_types'],
      [I18n.t('known_uris.unrecognized_measurement_values'), 'measurement_values'],
      [I18n.t('known_uris.unrecognized_measurement_units'), 'measurement_units'],
      [I18n.t('known_uris.unrecognized_association_types'), 'association_types'] ]
    @stats_filter_selected_option = params[:stats_filter]

    # TODO: Rebuild this. The queries involved time out.
    @uri_stats = []
    @stats_filter_selected_option = nil
    return true

    # NOTE: this is what needs rebuilding:
    case @stats_filter_selected_option
    when 'measurement_types'
      @uri_stats = measurements_stats
    when 'measurement_values'
      @uri_stats = measurement_values_stats
    when 'measurement_units'
      @uri_stats = measurement_units_stats
    when 'association_types'
      @uri_stats = assoication_types_stats
    else
      @stats_filter_selected_option = nil
      @uri_stats = nil
    end
  end

  def import_terms_from_ontology(uri_to_field_name_mappings)
    hide_from_glossary = (params[:known_uri][:hide_from_glossary] == "1")
    uri_type_id = params[:known_uri][:uri_type_id]
    ActiveRecord::Base.transaction do
      params[:selected_uris].each do |uri|
        if term_metadata = @terms[uri]
          attributes_by_language = {}
          term_metadata.each do |term_uri, attributes_from_ontology|
            if field_name = uri_to_field_name_mappings[term_uri]
              attributes_from_ontology.each do |attribute_metadata|
                language_iso = attribute_metadata[:language] || 'en'
                if language = Language::find_closest_by_iso(language_iso)
                  attributes_by_language[language] ||= {}
                  attributes_by_language[language][field_name] = attribute_metadata[:text]
                end
              end
            end
          end
          # find or create the KnownURI
          known_uri = KnownUri.find_or_create_by_uri(uri,
            hide_from_glossary: hide_from_glossary, uri_type_id: uri_type_id)
          # delete any existing definitions as they will be replaced
          known_uri.translated_known_uris.destroy_all
          # add in the definitions for each defined language
          attributes_by_language.each do |language, translation_fields|
            if language == Language.english # English is stored right on the model:
              known_uri.update_attributes(translation_fields)
            else
              TranslatedKnownUri.create(translation_fields.merge(known_uri: known_uri, language: language))
            end
          end
        end
      end
    end
  end

  def search_known_uris_by_name_or_uri(term)
    @known_uris = KnownUri.where([ "uri LIKE ? OR name LIKE ?", "%#{term}%", "%#{term}%" ])
  end

  def lookup_predicate
    @predicate = !params[:predicate_known_uri_id].blank? ? KnownUri.find_by_id(params[:predicate_known_uri_id]) : nil
    KnownUri.preload_associations(@predicate, { known_uri_relationships_as_subject: :to_known_uri })
  end

  def clear_cache
    EOL::Sparql::Client.clear_uri_caches
    KnownUri.clear_uri_caches
    expire_fragment('glossary_in_lang_' + current_language.iso_code)
  end

  def measurements_stats
    Rails.cache.fetch("/known_uris/measurements_stats", expires_in: $VIRTUOSO_CACHING_PERIOD.hours) do
      EOL::Sparql.connection.unknown_measurement_type_uris
    end
  end

  def measurement_values_stats
    Rails.cache.fetch("/known_uris/measurement_values_stats", expires_in: $VIRTUOSO_CACHING_PERIOD.hours) do
      EOL::Sparql.connection.unknown_measurement_value_uris
    end
  end

  def measurement_units_stats
    Rails.cache.fetch("/known_uris/measurement_units_stats", expires_in: $VIRTUOSO_CACHING_PERIOD.hours) do
      EOL::Sparql.connection.unknown_measurement_unit_uris
    end
  end

  def assoication_types_stats
    Rails.cache.fetch("/known_uris/assoication_types_stats", expires_in: $VIRTUOSO_CACHING_PERIOD.hours) do
      EOL::Sparql.connection.unknown_association_type_uris
    end
  end

end
