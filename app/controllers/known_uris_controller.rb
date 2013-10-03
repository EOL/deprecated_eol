class KnownUrisController < ApplicationController

  before_filter :set_page_title,
    :except => [ :autocomplete_known_uri_search, :autocomplete_known_uri_units, :autocomplete_known_uri_metadata,
                 :autocomplete_known_uri_predicates, :autocomplete_known_uri_values ]
  before_filter :restrict_to_admins_and_master_curators,
    :except => [ :autocomplete_known_uri_search, :autocomplete_known_uri_units, :autocomplete_known_uri_metadata,
                 :autocomplete_known_uri_predicates, :autocomplete_known_uri_values ]
  before_filter :set_stats_filter_options, :only => [ :index, :show_stats ]
  skip_before_filter :original_request_params, :global_warning, :set_locale, :check_user_agreed_with_terms,
    :only => [ :autocomplete_known_uri_search, :autocomplete_known_uri_units, :autocomplete_known_uri_metadata,
               :autocomplete_known_uri_predicates, :autocomplete_known_uri_values ]

  after_filter :clear_cache,
    :except => [:index, :show_stats,
                :autocomplete_known_uri_search, :autocomplete_known_uri_units, :autocomplete_known_uri_metadata,
                :autocomplete_known_uri_predicates, :autocomplete_known_uri_values ]

  layout 'v2/basic'

  def index
    wheres = { translated_known_uris: { language_id: [current_language.id, Language.default.id] } }
    if params[:category_id]
      wheres[:known_uris_toc_items] = { toc_item_id: params[:category_id] } if params[:category_id]
    else
      @uri_type ||= params.has_key?(:uri_type_id) ? UriType.find(params[:uri_type_id]) : UriType.measurement
      wheres[:uri_type_id] = @uri_type.id
    end
    @known_uris = KnownUri.includes([:uri_type, :toc_items, :translated_known_uris]).where(wheres).
      paginate(page: params[:page], order: 'position', :per_page => 500)
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
      render(:partial => 'stats_report')
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
      @existing_known_uris = KnownUri.where(uri: @terms.collect{ |uri, metadata| uri }).includes({ :translations => :language })
      if params[:importing]
        attribute_types_selected = {}
        attribute_mappings = { 'rdfs:label' => 'name' }
        SchemaTermParser.attribute_uris.each do |uri|
          if params.has_key?(uri.to_s)
            if params[uri.to_s].blank?
              flash[:error] = I18n.t('known_uris.please_select_field_types')
            elsif attribute_types_selected[params[uri.to_s]]
              flash[:error] = I18n.t('known_uris.more_than_one_field_mapped_to_type', :type => params[uri.to_s])
            elsif params[uri.to_s] != 'none'
              attribute_types_selected[params[uri.to_s]] = uri
              attribute_mappings[uri] = params[uri.to_s]
            end
          end
        end
        if params[:selected_uris].blank?
          flash[:error] = I18n.t('known_uris.please_select_uris_to_import')
        end
        if !flash[:error]
          import_terms_from_ontology(attribute_mappings)
          flash[:notice] = I18n.t('known_uris.import_successful')
          redirect_to known_uris_path
        end
      end
    end
  end

  def categories
    @recently_used = KnownUri.where(['uri IN (?)', session[:rec_uris]]) if session[:rec_uris]
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
    @translated_known_uri = @known_uri.translated_known_uris.build(language: current_language)
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
    @known_uri = KnownUri.find(params[:id], :include => [ :toc_items, :known_uri_relationships_as_subject ] )
    @translated_known_uri = @known_uri.translations.detect{ |t| t.language == current_language } || @known_uri.translated_known_uris.build(language: current_language)
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
    convert_allowed_value_and_unit_ids_to_relationships # Because they don't work without more information...
    if @known_uri.update_attributes(params[:known_uri])
      flash[:notice] = I18n.t(:known_uri_updated)
      redirect_back_or_default(known_uris_path(uri_type_id: @known_uri.uri_type_id))
    else
      render :action => "edit"
    end
  end

  def destroy
    @known_uri = KnownUri.find(params[:id])
    @known_uri.destroy
    redirect_to known_uris_path
  end

  # search for any URI by name or URI
  def autocomplete_known_uri_search
    @known_uris = search_known_uris_by_name_or_uri(params[:term])
    render_autocomplete_results
  end

  # search for primary measurement predicates. This won't be called unless there
  # is a term, so do a basic search and filter on measurement type
  def autocomplete_known_uri_predicates
    @known_uris = search_known_uris_by_name_or_uri(params[:term])
    @known_uris.delete_if{ |ku| ku.uri_type_id != UriType.measurement.id }
    render_autocomplete_results
  end

  # search for unit URIs. If the term is empty and given a predicate, use the
  # visible specified units as a pick list. If given a term, search for any
  # KnownUri which is a unit of measure value URI
  def autocomplete_known_uri_units
    lookup_predicate
    if params[:term].strip.blank?
      if @predicate && @predicate.has_units?
        @known_uris = @predicate.allowed_units.select{ |ku| ku.visible? }
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
    if @predicate
      if params[:term].strip.blank?
        if @predicate && @predicate.has_values?
          @known_uris = @predicate.allowed_values.select{ |ku| ku.visible? }
        else
          @known_uris = []
        end
      else
        @known_uris = search_known_uris_by_name_or_uri(params[:term])
        @known_uris.delete_if{ |ku| ! @predicate.allowed_values.include?(ku) }
      end
    end
    render_autocomplete_results
  end

  private

  def render_autocomplete_results
    @known_uris ||= []
    KnownUri.preload_associations(@known_uris, [ :uri_type, { :known_uri_relationships_as_subject => :to_known_uri } ])
    @known_uris.uniq!
    @known_uris.sort_by!(&:position)
    render :json => @known_uris.compact.uniq.collect{ |k| { :id => k.id, :value => k.name,
      :label => "#{k.name} (#{k.uri})", :uri_type => k.has_units? ? 'measurement' : nil,
      :has_values => k.has_values? ? '1' : nil }}.to_json
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
    case @stats_filter_selected_option
    when 'measurement_types'
      @uri_stats = KnownUri.unknown_measurement_type_uris
    when 'measurement_values'
      @uri_stats = KnownUri.unknown_measurement_value_uris
    when 'measurement_units'
      @uri_stats = KnownUri.unknown_measurement_unit_uris
    when 'association_types'
      @uri_stats = KnownUri.unknown_association_type_uris
    else
      @stats_filter_selected_option = nil
      @uri_stats = nil
    end
  end

  def import_terms_from_ontology(uri_to_field_name_mappings)
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
          known_uri = KnownUri.find_or_create_by_uri(uri)
          # delete any existing definitions as they will be replaced
          known_uri.translations.destroy_all
          # add in the definitions for each defined language
          attributes_by_language.each do |language, translation_fields|
            TranslatedKnownUri.create(translation_fields.merge(:known_uri => known_uri, :language => language))
          end
        end
      end
    end
  end

  # Allowed values cannot be added directly--the join model doesn't have the required URI...
  def convert_allowed_value_and_unit_ids_to_relationships
    # Okay, this is REALLY weird, but I couldn't find a way around it. When I was calling #known_uri_relationships_as_subject.clear, I was
    # getting ActiveRecord::StatementInvalid because it was trying to update the record before destroying it. I don't know why and I didn't
    # track it down. Instead, I use brute force:
    @known_uri.known_uri_relationships_as_subject.map(&:destroy) # This actually deletes them, but...
    @known_uri.known_uri_relationships_as_subject.clear          # ...this removes them from the "memory" on the model.
    if params[:known_uri][:allowed_values_target_ids]
      values = KnownUri.find(params[:known_uri].delete(:allowed_values_target_ids))
      params[:known_uri][:known_uri_relationships_as_subject] = values.map do |id|
        KnownUriRelationship.new(to_known_uri: KnownUri.find(id), from_known_uri: @known_uri,
                                 relationship_uri: KnownUriRelationship::ALLOWED_VALUE_URI)
      end
    else
      params[:known_uri][:known_uri_relationships_as_subject] = []
    end
    if params[:known_uri][:allowed_units_target_ids]
      units = KnownUri.find(params[:known_uri].delete(:allowed_units_target_ids))
      units.each do |id|
        params[:known_uri][:known_uri_relationships_as_subject] << 
          KnownUriRelationship.new(to_known_uri: KnownUri.find(id), from_known_uri: @known_uri,
                                   relationship_uri: KnownUriRelationship::ALLOWED_UNIT_URI)
      end
    else
      params[:known_uri][:known_uri_relationships_as_subject] ||= []
    end
  end

  def search_known_uris_by_name_or_uri(term)
    @known_uris = KnownUri.where([ "uri LIKE ?", "%#{term}%" ]) +
      TranslatedKnownUri.where([ "name LIKE ?", "%#{params[:term]}%" ]).includes(:known_uri).collect(&:known_uri).compact
  end

  def lookup_predicate
    @predicate = !params[:predicate_known_uri_id].blank? ? KnownUri.find_by_id(params[:predicate_known_uri_id]) : nil
    KnownUri.preload_associations(@predicate, { :known_uri_relationships_as_subject => :to_known_uri })
  end

  def clear_cache
    Rails.cache.delete("known_uri/all_measurement_type_uris")
  end

end
