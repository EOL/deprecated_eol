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
      format.html # index.html.erb
      format.xml  { render :xml => @collections }
    end
  end

  def show
    @collection = Collection.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @collection }
    end
  end

  # NOTE - I haven't really implemented this one yet.
  def new
    @page_title = I18n.t(:create_a_collection)
    @collection = Collection.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @collection }
    end
  end

  # NOTE - I haven't really implemented this one yet.
  def edit
    @page_title = I18n.t(:edit_collection)
    @collection = Collection.find(params[:id])
  end

  # NOTE - This can ONLY be called as a child of a Collection or without a parent at all (which assumes current_user).
  # TODO - Collection (as the parent) version of this method
  def create
    @collection = Collection.new(params[:collection])
    respond_to do |format|
      if @collection.save
        format.html { redirect_to(@collection, :notice => 'Collection was successfully created.') }
        format.xml  { render :xml => @collection, :status => :created, :location => @collection }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @collection.errors, :status => :unprocessable_entity }
      end
    end
  end

  # NOTE - I haven't really implemented this one yet.
  def update
    @collection = Collection.find(params[:id])
    respond_to do |format|
      if @collection.update_attributes(params[:collection])
        format.html { redirect_to(@collection, :notice => 'Collection was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @collection.errors, :status => :unprocessable_entity }
      end
    end
  end

  # NOTE - I haven't really implemented this one yet.
  def destroy
    @collection = Collection.find(params[:id])
    @collection.destroy
    respond_to do |format|
      format.html { redirect_to(collections_url) }
      format.xml  { head :ok }
    end
  end

  # This is ONLY possible on the current_user, so there is no code to handle Community or User.
  def collect
    @collection = current_user.inbox_collection
    object = find_collectable_item(params['type'], params['id'])
    @collection.add(object)
    respond_to do |format|
      format.html { redirect_to(@collection, :notice => I18n.t(:item_was_added_to_your_recently_collected_items) ) }
    end
  end

  # This is ONLY possible on the current_user, so there is no code to handle Community or User.
  def watch
    @collection = current_user.watch_collection
    object = find_collectable_item(params['type'], params['id'])
    @collection.add(object)
    respond_to do |format|
      format.html { redirect_to(@collection, :notice => I18n.t(:item_was_added_to_your_watched_items_collection) ) }
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

  # NOTE - Yes, you could do this with clever ruby code, but the case ensures we have a valid type and is clear:
  def find_collectable_item(type, id)
    object = case type
    when "TaxonConcept"
      TaxonConcept.find(id)
    when "User"
      User.find(id)
    when "DataObject"
      DataObject.find(id)
    when "Community"
      Community.find(id)
    when "Collection"
      Collection.find(id)
    else
      nil
    end
    raise EOL::Exceptions::InvalidCollectionItemType.new("I cannot create a collection item from a #{type}") unless
      object
    object
  end

end
