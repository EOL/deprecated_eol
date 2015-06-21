class CuratorsSuggestedSearchesController < ApplicationController

  include ActionView::Helpers::TextHelper
  include DataSearchHelper

  before_filter :restrict_to_master_curators
  layout 'curators_suggested_searches'

  def index
    @suggested_searches = CuratorsSuggestedSearch.all
  end
  def new
    @suggested_search =  CuratorsSuggestedSearch.new
    prepare_search_parameters(params)
    prepare_attribute_options
  end

  def create
    if params[:format]
      @suggested_search ||= CuratorsSuggestedSearch.find(params[:format])
    else
    @suggested_search ||=  CuratorsSuggestedSearch.new
    end
    debugger
    update_attributes(params)
    flash[:success] = 'suggestion added'
    redirect_to data_search_path
  end

  def edit
    @suggested_search =  CuratorsSuggestedSearch.find(params[:id])
    prepare_search_parameters(params)
    prepare_attribute_options
  end

  def update
    @suggested_search ||=  CuratorsSuggestedSearch.find(params[:format])
  end

  def destroy
   @suggested_search||= CuratorsSuggestedSearch.find(params[:id])
   @suggested_search.destroy
   flash[:success] = I18n.t :the_suggested_search_deleted
   redirect_to data_search_path
  end

  def  update_attributes(params)
    @suggested_search.update_attributes(params[:curators_suggested_search])
    @suggested_search.save
  end
end