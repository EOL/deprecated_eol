class KnownUrisController < ApplicationController

  before_filter :set_page_title, :except => :autocomplete_known_uri_uri
  before_filter :restrict_to_admins, :except => [ :index, :autocomplete_known_uri_uri ]
  skip_before_filter :original_request_params, :global_warning, :set_locale, :check_user_agreed_with_terms, :only => :autocomplete_known_uri_uri

  layout 'v2/basic'

  autocomplete :known_uri, :uri, :full => true

  def index
    @known_uris = params[:category_id] ?
      KnownUri.
        includes([:toc_items, :translated_known_uris]).
        where(translated_known_uris: { language_id: current_language.id }, known_uris_toc_items: { toc_item_id: params[:category_id] }).
        order('translated_known_uris.name') :
      KnownUri.paginate(page: params[:page], order: 'uri')
    respond_to do |format|
      format.html { }
      format.js { @category = TocItem.find(params[:category_id]) }
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
    if @known_uri.name.blank?
      @known_uri.translated_known_uris << [TranslatedKnownUri.new(language: current_language)]
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

end
