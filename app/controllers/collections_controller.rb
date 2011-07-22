# A bit tricky.
#
# You could come here looking at a Community's Collection.
# You could come here looking at a (specified) User's Collection. (show only)
#     UPDATE: user collections index is now in users/collections
# And you could come here without either of those (implying the current_user's Collection).
class CollectionsController < ApplicationController

  before_filter :find_collection, :except => [:new, :create]
  before_filter :find_parent, :only => [:show]
  before_filter :find_parent_for_current_user_only, :except => [:show, :collect, :watch]
  before_filter :build_collection_items_with_sorting_and_filtering, :only => [:show, :edit, :update]

  layout 'v2/collections'

  def show
    return copy if params[:commit_copy_collection_items]
    return move if params[:commit_move_collection_items]
    return remove if params[:commit_remove_collection_items]
    return chosen if params[:commit_chosen_collection]
    types = CollectionItem.types
    @collection_item_scopes  = [:selected_items, :all_items] + types.keys.map {|k| "all_#{types[k][:i18n_key]}"}
  end

  def new
    @page_title = I18n.t(:create_a_collection)
    @collection = Collection.new
  end

  def create
    @collection = Collection.new(params[:collection])
    if @collection.save
      CollectionActivityLog.create(:collection => @collection, :user => current_user, :activity => Activity.create)
      flash[:notice] = I18n.t(:collection_created_notice, :collection_name => @collection.name)
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
          return move
        else
          @collection.destroy
          flash[:error] = I18n.t(:collection_not_created_error, :collection_name => @collection.name)
          return redirect_to request.referer
        end
      end
    else
      flash[:error] = I18n.t(:collection_not_created_error, :collection_name => @collection.name)
      return redirect_to request.referer
    end
    # You shouldn't get here; something weird happened.
    flash[:error] = I18n.t(:collection_not_created_error, :collection_name => @collection.name)
    return redirect_to request.referer
  end

  def edit
    @site_column_id = 'collections_edit'
    @site_column_class = 'copy' # TODO - why?! (This was a HR thing.)
    @editing = true # TODO - there's a more elegant way to handle the difference in the layout...
    @head_title = I18n.t(:edit_collection_head_title, :collection_name => @collection.name) unless @collection.blank?
  end

  def update
    if @collection.update_attributes(params[:collection])
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:collection_updated_notice, :collection_name => @collection.name) if
            params[:colleciton] # NOTE - when we sort, we don't *actually* update params...
          return redirect_to params.merge!(:action => 'show').except(*unnecessary_keys_for_redirect)
        end
      end
    else
      flash[:error] = I18n.t(:collection_not_updated_error)
    end
  end

  # NOTE - I haven't really implemented this one yet... started to, but it's not USED anywhere, yet...
  def destroy
    if @collection.special?
      flash[:error] = I18n.t(:special_collections_cannot_be_destroyed)
      return redirect_to collection_url(@collection)
    else
      back = @collection.user ? user_collections_url(current_user) : community_url(@collection.community)
      @collection.destroy
      redirect_to(back)
    end
  end

  # /collections/choose GET
  def choose
    @action_to_take = :copy if params[:for] == 'copy'
    @action_to_take = :move if params[:for] == 'move'
    @all = params[:all_items_from_collection_id]
    @selected_collection_items = params[:collection_items]
    params[:collection_items] = nil
    @collections = current_user.collections # TODO: does this include community collections of which user is member?
    @page_title = I18n.t(:choose_collection_header)
  end

private

  def find_collection
    begin
      @collection = Collection.find(params[:id], :include => :collection_items)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = I18n.t(:collection_not_found_error)
      return redirect_back_or_default
    end
    @watch_collection = logged_in? ? current_user.watch_collection : nil
  end

  # When you're going to show a bunch of collection items and provide sorting and filtering capabilities:
  def build_collection_items_with_sorting_and_filtering
    @sort_options = [SortStyle.newest, SortStyle.oldest, SortStyle.alphabetical, SortStyle.reverse_alphabetical, SortStyle.richness, SortStyle.rating]
    @sort_by = SortStyle.find(params[:sort_by].blank? ? @collection.default_sort_style : params[:sort_by])
    @filter = params[:filter]
    @page = params[:page]
    @selected_collection_items = params[:collection_items] || []
    @facet_counts = EOL::Solr::CollectionItems.get_facet_counts(@collection.id)
    @collection_results = @collection.items_from_solr(:facet_type => @filter, :page => @page, :sort_by => @sort_by)
    @collection_items = @collection_results.map { |i| i['instance'] }
    if params[:commit_select_all]
      @selected_collection_items = @collection_items.map {|ci| ci.id.to_s }
    end
  end

  # When we bounce around, not all params are required; this is the list to remove:
  # NOTE - to use this as an parameter, you need to de-reference the array with a splat (*).
  def unnecessary_keys_for_redirect
    [:_method, :commit_sort, :commit_select_all, :commit_copy_collection_items, :commit, :collection,
     :commit_move_collection_items, :commit_remove_collection_items, :commit_edit_collection,
     :commit_chosen_collection]
  end

  def no_items_selected_error(which)
    flash[:warning] = I18n.t("items_no_#{which}_none_selected_warning")
    return redirect_to params.merge(:action => 'show').except(*unnecessary_keys_for_redirect)
  end

  def copy(all = false)
    if all
      params[:all_items_from_collection_id] = @collection.id
    else
      return no_items_selected_error(:copy) if params[:collection_items].nil? or params[:collection_items].empty?
    end
    return redirect_to params.merge(:action => 'choose', :for => 'copy').except(
      :filter, :sort_by, *unnecessary_keys_for_redirect)
  end

  def move(all = false)
    if all
      params[:all_items_from_collection_id] = @collection.id
    else
      return no_items_selected_error(:move) if params[:collection_items].nil? or params[:collection_items].empty?
    end
    return redirect_to params.merge(:action => 'choose', :for => 'move').except(:filter, :sort_by,
                                                                                *unnecessary_keys_for_redirect)
  end

  def remove(all = false)
    if all
      count = remove_items_from_collection(@collection.collection_items)
    else
      return no_items_selected_error(:remove) if params[:collection_items].nil? or params[:collection_items].empty?
      count = remove_items_from_collection(@collection_items.select {|ci| params['collection_items'].include?(ci.id.to_s) })
      @collection_items.delete_if {|ci| params['collection_items'].include?(ci.id.to_s) }
    end
    flash[:notice] = I18n.t(:removed_count_items_from_collection_notice, :count => count,
                            :collection => link_to_name(@collection))
    return redirect_to request.referer
  end

  def chosen
    if params[:copy] || params[:move]
      items = if params[:all_items_from_collection_id]
                CollectionItem.find_all_by_collection_id(params[:all_items_from_collection_id])
              else
                CollectionItem.find(params[:collection_items])
              end
      @collection.collection_items_attributes = copy_collection_items(items)
      if @collection.save
        if params[:move]
          old_collection = items.first.collection
          count = remove_items_from_collection(items)
          flash[:notice] = I18n.t(:removed_count_items_from_collection_notice, :count => count,
            :collection => link_to_name(old_collection))
        end
        return redirect_to(@collection)
      else
        flash[:error] = "FIXME something bad happened figure out a good error message to go here"
        return redirect_to request.referer
      end
    end
  end

  def copy_collection_items(collection_items)
    already_have = @collection.collection_items.map {|i| [i.object_id, i.object_type]}
    new_collection_items = []
    collection_items.each do |collection_item|
      new_collection_items << { :object_id => collection_item.object.id,
                                :object_type => collection_item.object_type,
                                :added_by_user_id => current_user.id } unless
        already_have.include?([collection_item.object.id, collection_item.object_type])
    end
    return new_collection_items
  end

  def find_parent
    if params[:collection_id]
      @parent = Collection.find(params[:collection_id], :include => :collection_items)
    else
      @parent = params[:user_id] ? User.find(params[:user_id]) : current_user
    end
  end

  def find_parent_for_current_user_only
    if params[:collection_id]
      @parent = Collection.find(params[:collection_id], :include => :collection_items)
    else
      @parent = current_user
    end
  end

  def remove_items_from_collection(items)
    count = 0
    items.each do |item|
      if item.update_attribute(:collection_id, nil) # Not actually destroyed, so that we can talk about it in feeds.
        item.remove_collection_item_from_solr # TODO - needed?  Or does the #after_save method handle this?
        count += 1
        CollectionActivityLog.create(:collection => @collection, :user => current_user,
                                     :activity => Activity.remove, :collection_item => item)
      end
    end
    return count
  end

  def link_to_name(collection)
    self.class.helpers.link_to(collection.name, collection_path(collection))
  end

end
