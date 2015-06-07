class CuratorsSuggestedSearchesController < ApplicationController

  before_filter :restrict_to_master_curators 
  def show
      @suggestion_search = CuratorsSuggestedSearch.find(params.find[:id])
  end
  def new
    @suggested_search =  CuratorsSuggestedSearch.new
  end
  
  def create
    @suggested_search.save
  end

  def edit
    
  end

  def update
    
  end

  def destroy
   @suggested_search||= CuratorsSuggestedSearch.find(params[:id])
   @suggested_search.destroy
   flash[:success] = I18n.t :the_suggested_search_deleted
   redirect_to request.referrer || root_url

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
end
