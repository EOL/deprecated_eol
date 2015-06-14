class CuratorsSuggestedSearchesController < ApplicationController

  include DataSearchHelper

  before_filter :restrict_to_master_curators
  layout 'curators_suggested_searches'

  def new
    @suggested_search = CuratorsSuggestedSearch.new
    prepare_search_parameters(params)
    prepare_attribute_options
  end
  
  def create
    if params[:format]
      @suggested_search ||= CuratorsSuggestedSearch.find(params[:format])
    else
    @suggested_search ||= CuratorsSuggestedSearch.new
    end
    if params[:taxon_concept_id].blank? && !(params[:taxon_name].blank?)
      results_with_suggestions = EOL::Solr::SiteSearch.simple_taxon_search(params[:taxon_name], language: current_language)
      results = results_with_suggestions[:results]
      if !(results.blank?)
        @taxon_concept = results[0]['instance']
        params[:curators_suggested_search][:taxon_concept_id]= @taxon_concept.id
      end
    end
    update_attributes(params)
    respond_to do |format|
      format.html do
        redirect_to data_search_path
        flash.now[:success] = I18n.t :curators_suggested_searches_added
      end
      format.js do
        # render partial: 'curators_suggested_searches/index', layout: false, locals: { return_to: submit_to }
      end
    end
  end

  def edit
    @suggested_search = CuratorsSuggestedSearch.find(params[:id])
    prepare_search_parameters(params)
    prepare_attribute_options
    @taxon_concept = TaxonConcept.find_by_id(@suggested_search.taxon_concept_id)

  end

  def update
    @suggested_search ||= CuratorsSuggestedSearch.find(params[:format])
  end

  def destroy
   @suggested_search||= CuratorsSuggestedSearch.find(params[:id])
   @suggested_search.destroy
   respond_to do |format|
      format.html do
        redirect_to data_search_path
        flash.now[:success] = I18n.t :curators_suggested_searches_deleted
      end
      format.js do
        # render partial: 'curators_suggested_searches/index', layout: false, locals: { return_to: submit_to }
      end
    end
  end

  def update_attributes(params)
    @suggested_search.update_attributes(params[:curators_suggested_search])
    @suggested_search.save
  end
end