class KnownUrisController < ApplicationController

  before_filter :force_login
  before_filter :set_page_title

  layout 'v2/basic'

  def index
    @known_uris = KnownUri.paginate(page: params[:page])
  end

  def show
    @known_uri = KnownUri.find(params[:id])
  end

  def new
    @known_uri = KnownUri.new
  end

  def create
    @known_uri = KnownUri.new(params[:known_uri])
    if @known_uri.save
      flash[:notice] = I18n.t(:known_uri_created)
      redirect_back_or_default(known_uris_path)
    else
      render :action => "new"
    end
  end

  def edit
    @known_uri = KnownUri.find(params[:id])
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

  private

  def set_page_title
    @page_title = I18n.t(:known_uris_page_title)
  end

end
