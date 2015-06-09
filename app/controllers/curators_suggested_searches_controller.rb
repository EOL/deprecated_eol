class CuratorsSuggestedSearchesController < ApplicationController

  before_filter :restrict_to_master_curators
  before_filter :modal, only: [:new, :edit]
  before_filter :prepare_attribute_options, only: [:new, :edit]
  # before_filter :prepare_search_parameters, only: [:edit, :new]
  layout 'curators_suggested_searches'
    include ActionView::Helpers::TextHelper

  def show
      @suggestion_search = CuratorsSuggestedSearch.find(params[:id])
  end
  def new
    @suggested_search =  CuratorsSuggestedSearch.new
  end
  
  def create
    @suggested_search.save
  end

  def edit
    @suggested_search =  CuratorsSuggestedSearch.find(params[:id])
  end

  def update
    
  end

  def destroy
   @suggested_search||= CuratorsSuggestedSearch.find(params[:id])
   @suggested_search.destroy
   flash[:success] = I18n.t :the_suggested_search_deleted
   redirect_to request.referrer || root_url

  end

   def modal
    @modal = true # When this is JS, we need a "go back" link at the bottom if there's an error, and this needs
                  # to be set super-early!
  end

  def prepare_attribute_options
    @attribute_options = []
    if @taxon_concept && TaxonData.is_clade_searchable?(@taxon_concept)
      # Get URIs (attributes) that this clade has measurements or facts for.
      # NOTE excludes associations URIs e.g. preys upon.
      measurement_uris = EOL::Sparql.connection.all_measurement_type_known_uris_for_clade(@taxon_concept)
      @attribute_options = convert_uris_to_options(measurement_uris)
      @clade_has_no_data = true if @attribute_options.blank?
    end

    if @attribute_options.blank?
      # NOTE - because we're pulling this from Sparql, user-added known uris may not be included. However, it's superior to
      # KnownUri insomuch as it ensures that KnownUris with NO data are ignored.
      measurement_uris = EOL::Sparql.connection.all_measurement_type_known_uris
      @attribute_options = convert_uris_to_options(measurement_uris)
    end

    if @attribute.blank?
      # NOTE we should (I assume) only get nil attribute when the user first
      #      loads the search, so for that context we select an example default,
      #      starting with [A-Z] seems more readable. If my assumption is wrong
      #      then we should rethink this and tell the user why attribute is nil
      match = @attribute_options.select{|o| o[0] =~ /^[A-Z]/}
      @attribute_default = match.first[1] unless match.blank?
    end
  end
#   
  def convert_uris_to_options(measurement_uris)
    # TODO - this could be greatly simplified with duck-typing.  :|
    measurement_uris.collect do |uri|
      label = uri.respond_to?(:name) ? uri.name : EOL::Sparql.uri_to_readable_label(uri)
      if label.nil?
        nil
      else
        [ truncate(label, length: 30),
          uri.respond_to?(:uri) ? uri.uri : uri,
          { 'data-known_uri_id' => uri.respond_to?(:id) ? uri.id : nil } ]
      end
    end.compact.sort_by { |o| o.first.downcase }.uniq
  end
# def prepare_search_parameters(options)
#   
# 
    # # Look up attribute based on query
    # unless @querystring.blank? || EOL::Sparql.connection.all_measurement_type_uris.include?(@attribute)
      # @attribute_known_uri = KnownUri.by_name(@querystring).first
      # if @attribute_known_uri
        # @attribute = @attribute_known_uri.uri
        # @querystring = options[:q] = ''
      # end
    # else
      # @attribute_known_uri = KnownUri.find_by_uri(@attribute)
    # end
    # @attributes = @attribute_known_uri ? @attribute_known_uri.label : @attribute
    # if @required_equivalent_attributes
      # @required_equivalent_attributes.each do |attr|
        # @attributes += " + #{KnownUri.find(attr.to_i).label}"
      # end
    # end
#     
#   
#     
    # if @attribute_known_uri && ! @attribute_known_uri.units_for_form_select.blank?
      # @units_for_select = @attribute_known_uri.units_for_form_select
    # else
      # @units_for_select = KnownUri.default_units_for_form_select
    # end
# 
  # end
  end