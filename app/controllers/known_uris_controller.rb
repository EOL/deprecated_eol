class KnownUrisController < ApplicationController

  before_filter :set_page_title, :except => :autocomplete_known_uri_uri
  before_filter :restrict_to_admins_and_master_curators, :except => [ :autocomplete_known_uri_uri ]
  before_filter :set_stats_filter_options, :only => [ :index, :show_stats ]
  skip_before_filter :original_request_params, :global_warning, :set_locale, :check_user_agreed_with_terms, :only => :autocomplete_known_uri_uri

  layout 'v2/basic'

  autocomplete :known_uri, :uri, :full => true

  def index
    wheres = { translated_known_uris: { language_id: [current_language.id, Language.default.id] } }
    wheres[:known_uris_toc_items] = { toc_item_id: params[:category_id] } if params[:category_id]
    @known_uris = KnownUri.includes([:toc_items, :translated_known_uris]).where(wheres).
      paginate(page: params[:page], order: 'position', :per_page => 500)
    respond_to do |format|
      format.html { }
      format.js { @category = TocItem.find(params[:category_id]) }
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
    @known_uri = KnownUri.new(params[:known_uri])
    if @known_uri.save
      flash[:notice] = I18n.t(:known_uri_created)
      redirect_back_or_default(known_uris_path)
    else
      render action: 'new'
    end
  end

  def edit
    @known_uri = KnownUri.find(params[:id], :include => [ :toc_items, :known_uri_relationships_as_subject ] )
    @translated_known_uri = @known_uri.translations.detect{ |t| t.language == current_language } || @known_uri.translated_known_uris.build(language: current_language)
  end

  # TODO - this seems a bit much, but this is a controller that will see a lot of use for a month, and then almost none... so I don't care much right now.
  # Still, this could be made efficient. I'm just going off of http://quickworx.info/using-jquery-drag-and-drop-to-order-div-based-tables-in-rails/ for
  # now...
  def sort
    @known_uris = KnownUri.all # Yes, really.
    @known_uris.each do |uri|
      uri.position = params['known_uris'].index("known_uri_#{uri.id}") + 1
      uri.save
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
    redirect_to action: 'index'
  end

  def hide 
    @known_uri = KnownUri.find(params[:id])
    if current_user.is_admin?
      @known_uri.hide(current_user)
    end
    redirect_to action: 'index'
  end

  def update
    @known_uri = KnownUri.find(params[:id])
    if @known_uri.update_attributes(params[:known_uri])
      flash[:notice] = I18n.t(:known_uri_updated)
      redirect_back_or_default(known_uris_path)
    else
      render :action => "edit"
    end
  end

  def destroy
    @known_uri = KnownUri.find(params[:id])
    @known_uri.destroy
    redirect_to known_uris_path
  end

  def autocomplete_known_uri_uri
    @known_uris = KnownUri.where([ "uri LIKE ?", "%#{params[:term]}%" ]) +
      TranslatedKnownUri.where([ "name LIKE ?", "%#{params[:term]}%" ]).collect(&:known_uri)
    render :json => @known_uris.compact.uniq.collect{ |k| { :id => k.id, :value => k.uri, :label => k.uri }}.to_json
  end

  private

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
