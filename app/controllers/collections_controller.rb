# A bit tricky.
#
# You could come here looking at a Community's Collection.
# You could come here looking at a (specified) User's Collection. (index and show only)
#     UPDATE: user collections index is now in users/collections
# And you could come here without either of those (implying the current_user's Collection).
class CollectionsController < ApplicationController

  before_filter :find_parent, :only => [:index, :show]
  before_filter :find_parent_for_current_user_only, :except => [:index, :show, :collect, :watch]

  layout 'v2/collections'

  # NOTE - I haven't really implemented this one yet.
  def index
    @collections = Collection.all
    respond_to do |format|
      format.html
    end
  end

  def show
    @collection = Collection.find(params[:id])
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    if params[:filter]
      @collection_items = @collection.filter_type(params[:filter]).compact
    else
      @collection_items = @collection.collection_items
    end
    respond_to do |format|
      format.html
    end
  end

  # NOTE - I haven't really implemented this one yet.
  def new
    @page_title = I18n.t(:create_a_collection)
    @collection = Collection.new
    respond_to do |format|
      format.html
    end
  end

  # NOTE - This can ONLY be called as a child of a Collection or without a parent at all (which assumes current_user).
  # TODO - Collection (as the parent) version of this method
  def create
    @collection = Collection.new(params[:collection])
    respond_to do |format|
      if @collection.save
        format.html { redirect_to(@collection, :notice => I18n.t(:collection_created_notice, :collection_name => @collection.name)) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def edit
    @collection = Collection.find(params[:id])
    @head_title = I18n.t(:edit_collection_head_title, :collection_name => @collection.name) unless @collection.blank?
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @collection_items = @collection.collection_items
  end

  def update
    @collection = Collection.find(params[:id])
    return_to = params[:return_to]
    return_to ||= collections_path(@collection) unless @collection.blank?
    store_location(return_to)
    if @collection.update_attributes(params[:collection])
      flash[:notice] = I18n.t(:collection_updated_notice, :collection_name => @collection.name)
    else
      flash[:error] = I18n.t(:collection_not_updated_error)
    end
    redirect_back_or_default
  end

  # NOTE - I haven't really implemented this one yet.
  def destroy
    @collection = Collection.find(params[:id])
    @collection.destroy
    respond_to do |format|
      format.html { redirect_to(collections_url) }
    end
  end

private

  def find_parent
    if params[:collection_id]
      @parent = Collection.find(params[:collection_id])
    else
      @parent = params[:user_id] ? User.find(params[:user_id]) : current_user
    end
  end

  def find_parent_for_current_user_only
    if params[:collection_id]
      @parent = Collection.find(params[:collection_id])
    else
      @parent = current_user
    end
  end

end
