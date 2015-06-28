#encoding: utf-8

class CuratorsSuggestedSearchesController < ApplicationController

  include DataSearchHelper
  include ActionView::Helpers::TextHelper
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
    if params[:taxon_concept_id].to_i != @suggested_search.taxon_concept_id
      params[:curators_suggested_search][:taxon_concept_id]=  params[:taxon_concept_id]
    elsif !(params[:taxon_name].blank?)
      results_with_suggestions = EOL::Solr::SiteSearch.simple_taxon_search(params[:taxon_name], language: current_language)
      results = results_with_suggestions[:results]
      if !(results.blank?)
        @taxon_concept = results[0]['instance']
        params[:curators_suggested_search][:taxon_concept_id]= @taxon_concept.id
      end
    end
    update_attributes(params)
    redirect_to data_search_path
    flash.now[:notice] = I18n.t :curators_suggested_searches_added
  end

  def edit
    @suggested_search = CuratorsSuggestedSearch.find(params[:id])
    prepare_search_parameters(params)
    prepare_attribute_options
    @taxon_concept = TaxonConcept.find_by_id(@suggested_search.taxon_concept_id)
    @attribute = convert_uris_to_options([@suggested_search.uri])

  end

  def update
    @suggested_search ||= CuratorsSuggestedSearch.find(params[:format])
  end

  def destroy
    @suggested_search||= CuratorsSuggestedSearch.find(params[:id])
    @suggested_search.destroy
    redirect_to data_search_path
    flash.now[:notice] = I18n.t :curators_suggested_searches_deleted
  end

  def update_attributes(params)
    @suggested_search.update_attributes(params[:curators_suggested_search])
    @suggested_search.save
  end
end