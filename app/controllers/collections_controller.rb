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
  end

  def show
    begin
      @collection = Collection.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:error] = I18n.t(:collection_not_found_error)
      return redirect_back_or_default
    end
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @sort_by = params[:sort_by] ? params[:sort_by] : 'newest'
    @filter = params[:filter] ? params[:filter] : ''
    @select_all = params[:commit_select_all] ? true : false
    @selected_collection_items = params[:collection_items] || []
    if @filter.blank?
      @collection_items = @collection.collection_items
    else
      @collection_items = @collection.filter_type(@filter).compact
    end
    @collection_items = CollectionItem.custom_sort(@collection_items, @sort_by)
  end

  # NOTE - I haven't really implemented this one yet.
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
    selected_items = params[:collection_items]
    if selected_items
      if params[:copy]
        @collection.collection_items_attributes = copy_collection_items(CollectionItem.find(selected_items))
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
    @collection = Collection.find(params[:id])
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @sort_by = params[:sort_by] ? params[:sort_by] : 'newest'
    @filter = params[:filter] ? params[:filter] : ''
    @select_all = params[:commit_select_all] ? true : false
    @selected_collection_items = params[:collection_items] || []
    if @filter.blank?
      @collection_items = @collection.collection_items
    else
      @collection_items = @collection.filter_type(@filter).compact
    end
    @collection_items = CollectionItem.custom_sort(@collection_items, @sort_by)
    @head_title = I18n.t(:edit_collection_head_title, :collection_name => @collection.name) unless @collection.blank?
  end

  # all buttons on show and edit are in a single form so update handles
  # copying, moving and removing collection items through nested attributes,
  # as well as updating collection itself - hence the complexity of the logic here
  def update
    commit = action_to_take?
    selected_items = params[:collection_items]

    if commit == :sort || commit == :select_all
      return redirect_to params.merge!(:action => params[:action_name] || 'show').except(:action_name, :_method, :commit_sort)
    elsif (commit == :copy || commit == :move || commit == :remove) && selected_items.blank?
      flash[:warning] = I18n.t("items_no_#{commit.to_s}_none_selected_warning")
      return redirect_to params.merge!(:action => params[:action_name] || 'show').except(:action_name, :_method, "commit_#{commit}_collection_items")
    elsif commit == :copy || commit == :move
      return redirect_to params.merge!(:action => 'choose', commit => true).except(:action_name, :_method, :id, "commit_#{commit}_collection_items", :filter, :sort_by)
    elsif commit == :remove
      # TODO: delete collection items
      flash[:notice] = 'NOT YET IMPLEMENTED'
      return redirect_to request.referer
    elsif commit == :edit
      @collection = Collection.find(params[:id])
      if @collection.update_attributes(params[:collection])
        flash[:notice] = I18n.t(:collection_updated_notice, :collection_name => @collection.name)
      else
        flash[:error] = I18n.t(:collection_not_updated_error)
      end
    elsif commit == :chosen
      @collection = Collection.find(params[:id])
      if params[:copy]
        @collection.collection_items_attributes = copy_collection_items(CollectionItem.find(selected_items))
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
    redirect_to request.referer # we shouldn't get here
  end

  # NOTE - I haven't really implemented this one yet.
  def destroy
    @collection = Collection.find(params[:id])
    @collection.destroy
    respond_to do |format|
      format.html { redirect_to(collections_url) }
    end
  end

  # /collections/choose GET
  def choose
    @action_to_take = :copy if params[:copy]
    @action_to_take = :move if params[:move]
    @selected_collection_items = params[:collection_items]
    params[:collection_items] = nil
    @collections = current_user.collections # TODO: does this include community collections of which user is member?
    @page_title = I18n.t(:choose_collection_header)
  end

private

  def action_to_take?
    return :sort if params[:commit_sort]
    return :select_all if params[:commit_select_all]
    return :copy if params[:commit_copy_collection_items]
    return :move if params[:commit_move_collection_items]
    return :remove if params[:commit_remove_collection_items]
    return :edit if params[:commit_edit_collection]
    return :chosen if params[:commit_chosen_collection]
    nil
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
