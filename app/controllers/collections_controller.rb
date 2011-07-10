# A bit tricky.
#
# You could come here looking at a Community's Collection.
# You could come here looking at a (specified) User's Collection. (index and show only)
#     UPDATE: user collections index is now in users/collections
# And you could come here without either of those (implying the current_user's Collection).
class CollectionsController < ApplicationController

  before_filter :find_collection, :except => [:index, :new, :create]
  before_filter :find_parent, :only => [:index, :show]
  before_filter :find_parent_for_current_user_only, :except => [:index, :show, :collect, :watch]
  before_filter :build_collection_items_with_sorting_and_filtering, :only => [:show, :edit]

  layout 'v2/collections'

  # NOTE - I haven't really implemented this one yet.
  def index
    @collections = Collection.all
  end

  def show
    puts '&' * 111
    return copy if params[:commit_copy_collection_items]
    return move if params[:commit_move_collection_items]
  end

  def new
    @page_title = I18n.t(:create_a_collection)
    @collection = Collection.new
  end

  def create
    @collection = Collection.new(params[:collection])
    if @collection.save
      CollectionActivityLog.create(:collection => self, :user => current_user, :activity => Activity.create)
      flash[:notice] = I18n.t(:collection_created_notice, :collection_name => @collection.name)
    else
      flash[:error] = I18n.t(:collection_not_created_error, :collection_name => @collection.name)
      return redirect_to request.referer
    end
    if params[:collection_items]
      if params[:copy]
        @collection.collection_items_attributes = copy_collection_items(CollectionItem.find(params[:collection_items]))
        if @collection.save
          return redirect_to @collection
        else
          flash[:error] = I18n.t(:items_no_copy_error, :collection_name => @collection.name)
          return redirect_to request.referer
        end
      elsif params[:move]
        flash[:notice] = 'TODO move items'
      end
    end
  end

  def edit
    @head_title = I18n.t(:edit_collection_head_title, :collection_name => @collection.name) unless @collection.blank?
  end

  # When is an update not really an update?  When we clicked a different button.  There are many:
  def update
    return select_all if params[:commit_select_all]
    return copy if params[:commit_copy_collection_items]
    return move if params[:commit_move_collection_items]
    return remove if params[:commit_remove_collection_items]
    return real_update if params[:commit_edit_collection]
    return chosen if params[:commit_chosen_collection] # TODO - I would think we want this to go to the appropriate action.
    flash[:warning] = I18n.t(:unknown_action_error)
    redirect_back_or_default
  end

  # NOTE - I haven't really implemented this one yet.
  def destroy
    if @collection.special?
      flash[:error] = I18n.t(:special_collections_cannot_be_destroyed)
      return redirect_to request.referer
    else
      @collection.destroy
    end
    respond_to do |format|
      format.html { redirect_to(collections_url) }
    end
  end

  # /collections/choose GET
  def choose
    puts "CHOOSE" * 20
    @action_to_take = :copy if params[:copy]
    @action_to_take = :move if params[:move]
    @selected_collection_items = params[:collection_items]
    params[:collection_items] = nil
    @collections = current_user.collections # TODO: does this include community collections of which user is member?
    @page_title = I18n.t(:choose_collection_header)
  end

private

  def find_collection
    begin
      @collection = Collection.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = I18n.t(:collection_not_found_error)
      return redirect_back_or_default
    end
    @watch_collection = logged_in? ? current_user.watch_collection : nil
  end

  # When you're going to show a bunch of collection items and provide sorting and filtering capabilities:
  def build_collection_items_with_sorting_and_filtering
    @sort_options = [SortStyle.newest, SortStyle.oldest]
    @sort_by = params[:sort_by].blank? ? SortStyle.newest.id : params[:sort_by].to_i
    @filter = params[:filter].blank? ? '' : params[:filter]
    @selected_collection_items = params[:collection_items] || []
    if @filter.blank?
      @collection_items = @collection.collection_items
    else
      @collection_items = @collection.filter_type(@filter).compact
    end
    @collection_items = CollectionItem.custom_sort(@collection_items, @sort_by)
    if params[:commit_select_all]
      @selected_collection_items = @collection_items.map {|ci| ci.id.to_s }
    end
  end

  # When we bounce around, not all params are required; this is the list to remove:
  # NOTE - to use this as an parameter, you need to de-reference the array with a splat (*).
  def unnecessary_keys_for_redirect
    [:action_name, :_method, :commit_sort, :commit_select_all, :commit_copy_collection_items,
     :commit_move_collection_items, :commit_remove_collection_items, :commit_edit_collection,
     :commit_chosen_collection]
  end

  def select_all
    return redirect_to params.merge!(:action => 'edit').except(*unnecessary_keys_for_redirect)
  end

  def no_items_selected_error(which)
    flash[:warning] = I18n.t("items_no_#{which}_none_selected_warning")
    return redirect_to params.merge(:action => params[:action_name] || 'show').except(*unnecessary_keys_for_redirect)
  end

  def copy
    puts "COPY" * 25
    return no_items_selected_error(:copy) if params[:collection_items].nil? or params[:collection_items].empty?
    return redirect_to params.merge(:action => 'choose', :action_to_take => 'copy').except(
      :filter, :sort_by, *unnecessary_keys_for_redirect)
  end

  def move
    return no_items_selected_error(:move) if params[:collection_items].nil? or params[:collection_items].empty?
    return redirect_to params.merge(:action => 'choose', :action_to_take => 'move').except(
      :filter, :sort_by, *unnecessary_keys_for_redirect)
  end

  def remove
    return no_items_selected_error(:remove) if params[:collection_items].nil? or params[:collection_items].empty?
    # TODO: delete collection items
    flash[:notice] = 'NOT YET IMPLEMENTED'
    return redirect_to request.referer
  end

  def real_update
    if @collection.update_attributes(params[:collection])
      flash[:notice] = I18n.t(:collection_updated_notice, :collection_name => @collection.name)
      return redirect_to(@collection)
    else
      flash[:error] = I18n.t(:collection_not_updated_error)
    end
  end

  # TODO - Not sure this is what we want to do. see #update
  def chosen
    if params[:copy]
      @collection.collection_items_attributes = copy_collection_items(CollectionItem.find(params[:collection_items]))
      if @collection.save
        return redirect_to(@collection) # should we go to new collection or back to copied from collection
      else
        flash[:error] = "FIXME something bad happened figure out a good error message to go here"
        return redirect_to request.referer
      end
    elsif params[:move]
      flash[:notice] = 'TODO move items'
    end
  end

  def copy_collection_items(collection_items)
    new_collection_items = []
    collection_items.each do |collection_item|
      new_collection_items << { :object_id => collection_item.object.id,
                                :object_type => collection_item.object_type,
                                :added_by_user_id => current_user.id }
    end
    return new_collection_items
  end

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
