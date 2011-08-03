# A bit tricky.
#
# You could come here looking at a Community's Collection.
# You could come here looking at a (specified) User's Collection. (show only)
#     UPDATE: user collections index is now in users/collections
# And you could come here without either of those (implying the current_user's Collection).
#
# NOTE - we use these commit_* button names because we don't want to parse the I18n of the button name (hard).
class CollectionsController < ApplicationController

  before_filter :find_collection, :except => [:new, :create]
  before_filter :find_parent, :only => [:show]
  before_filter :find_parent_for_current_user_only, :except => [:show, :collect, :watch]
  before_filter :build_collection_items_with_sorting_and_filtering, :only => [:show, :update]

  layout 'v2/collections'

  def show
    render :action => 'newsfeed' if @filter == 'newsfeed'
    return copy_items_and_redirect(@collection, current_user.watch_collection) if params[:commit_collect]
    # NOTE - this is complicated. It's getting the various collection item types and doing i18n on the name as well
    # as passing the raw facet type (used by Solr) as the values in the option hash that will be built in the view:
    types = CollectionItem.types
    @collection_item_scopes = [[I18n.t(:selected_items), :selected_items], [I18n.t(:all_items), :all_items]] +
      types.keys.map {|k| [I18n.t("all_#{types[k][:i18n_key]}"), k]}
  end

  def new
    @page_title = I18n.t(:create_a_collection)
    @collection = Collection.new
  end

  def create
    @collection = Collection.new(params[:collection])
    if @collection.save
      flash[:notice] = I18n.t(:collection_created_notice, :collection_name => link_to_name(@collection))
      source = Collection.find(params[:source_collection_id])
      if source.nil?
        @collection.destroy
        flash[:notice] = nil # We're undoing the create.
        flash[:error] = I18n.t(:could_not_find_collection_error)
        return redirect_to collection_path(@collection)
      end
      if params[:for] == 'copy'
        CollectionActivityLog.create(:collection => @collection, :user => current_user, :activity => Activity.create)
        return copy_items_and_redirect(source, @collection)
      elsif params[:for] == 'move'
        CollectionActivityLog.create(:collection => @collection, :user => current_user, :activity => Activity.create)
        return copy_items_and_redirect(source, @collection, :move => true)
      else
        @collection.destroy
        flash[:notice] = nil # We're undoing the create.
        flash[:error] = I18n.t(:collection_not_created_error, :collection_name => @collection.name)
        return redirect_to collection_path(@collection)
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
    set_edit_vars
  end

  def update
    return redirect_to_choose(:copy) if params[:commit_copy]
    return redirect_to_choose(:move) if params[:commit_move]
    return remove_and_redirect if params[:commit_remove]
    return annotate if params[:commit_annotation]
    return redirect_to params.merge!(:action => 'show').except(*unnecessary_keys_for_redirect) if params[:commit_sort]
    return chosen if params[:scope] # Note that updating the collection params doesn't specify a scope.
    if @collection.update_attributes(params[:collection])
      upload_logo(@collection) unless params[:collection][:logo].blank?
      flash[:notice] = I18n.t(:collection_updated_notice, :collection_name => @collection.name) if
        params[:colleciton] # NOTE - when we sort, we don't *actually* update params...
      redirect_to params.merge!(:action => 'show').except(*unnecessary_keys_for_redirect)
    else
      set_edit_vars
      render :action => :edit
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
    @site_column_id = 'collections_choose'
    @selected_collection_items = params[:collection_items]
    @for   = params[:for]
    @scope = params[:scope]
    @collections = current_user.all_collections
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
    set_sort_options
    @sort_by = SortStyle.find(params[:sort_by].blank? ? @collection.default_sort_style : params[:sort_by])
    @filter = params[:filter]
    @page = params[:page]
    @selected_collection_items = params[:collection_items] || []
    # NOTE - you still need these counts on the Update page:
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
    [:_method, :commit_sort, :commit_select_all, :commit_copy, :commit, :collection,
     :commit_move, :commit_remove, :commit_edit_collection, :commit_collect]
  end

  def no_items_selected_error(which)
    flash[:warning] = I18n.t("items_no_#{which}_none_selected_warning")
    return redirect_to params.merge(:action => 'show').except(*unnecessary_keys_for_redirect)
  end

  def redirect_to_choose(for_what)
    if params[:scope] == 'selected_items'
      return no_items_selected_error(:copy) if params[:collection_items].nil? or params[:collection_items].empty?
    end
    return redirect_to params.merge(:action => 'choose', :for => for_what).except(*unnecessary_keys_for_redirect)
  end

  def chosen
    source = Collection.find(params[:source_collection_id])
    if source.nil?
      flash[:error] = I18n.t(:could_not_find_collection_error)
      return redirect_to collection_path(@collection)
    end
    case params[:for]
    when 'move'
      return copy_items_and_redirect(source, @collection, :move => true)
    when 'copy'
      return copy_items_and_redirect(source, @collection)
    else
      flash[:error] = I18n.t(:action_not_available_error)
      return redirect_to collection_path(source)
    end
  end

  def copy_items_and_redirect(source, destination, options = {})
    copied = copy_items(:from => source, :to => destination, :items => params[:collection_items],
                        :scope => params[:scope])
    if copied > 0
      if options[:move]
        # Not handling any weird errors here, to simplify flash notice handling.
        remove_items(:from => source, :items => params[:collection_items], :scope => params[:scope])
        @collection_items.delete_if {|ci| params['collection_items'].include?(ci.id.to_s) } if @collection_items
        flash[:notice] = I18n.t(:moved_items_from_collection_with_count_notice, :count => copied,
                                :name => link_to_name(source))
        return redirect_to collection_path(destination)
      else
        flash[:notice] = I18n.t(:copied_items_from_collection_with_count_notice, :count => copied,
                                :name => link_to_name(source))
        return redirect_to collection_path(destination)
      end
    elsif copied == 0
      # Assume the flash message was set by #copy_items
      return redirect_to collection_path(source)
    else
      # Assume the flash message was set by #copy_items
      return redirect_to collection_path(source)
    end
  end

  def copy_items(options)
    collection_items = collection_items_with_scope(options)
    already_have = options[:to].collection_items.map {|i| [i.object_id, i.object_type]}
    new_collection_items = []
    collection_items.each do |collection_item|
      collection_item = CollectionItem.find(collection_item) # sometimes this is just an id.
      unless already_have.include?([collection_item.object.id, collection_item.object_type])
        new_collection_items << { :object_id => collection_item.object.id,
                                  :object_type => collection_item.object_type,
                                  :annotation => collection_item.annotation,
                                  :added_by_user_id => current_user.id }
        CollectionActivityLog.create(:collection => @collection, :user => current_user,
                                     :activity => Activity.collect, :collection_item => collection_item)
      end
    end
    if new_collection_items.empty?
      flash[:error] = I18n.t(:no_items_were_copied_error)
      return(0)
    end
    options[:to].collection_items_attributes = new_collection_items
    if options[:to].save
      return new_collection_items.length
    else
      flash[:error] = I18n.t(:unable_to_copy_items_error)
    end
  end

  def remove_and_redirect
    count = remove_items(:from => @collection, :items => params[:collection_items], :scope => params[:scope])
    flash[:notice] = I18n.t(:removed_count_items_from_collection_notice, :count => count)
    return redirect_to collection_path(@collection)
  end

  def annotate
    if @collection.update_attributes(params[:collection])
      respond_to do |format|
        format.js do
          # Sorry this is confusing, but we don't know which attribute number will have the id:
          @collection_item = CollectionItem.find(params[:collection][:collection_items_attributes].keys.map {|i|
            params[:collection][:collection_items_attributes][i][:id] }.first)
          render :partial => 'edit_collection_item', :locals => { :collection_item => @collection_item }
        end
      end
    else
      respond_to do |format|
        format.js { render :text => I18n.t(:item_not_updated_in_collection_error) }
        format.html do
          flash[:error] = I18n.t(:item_not_updated_in_collection_error)
          redirect_to(@collection_item.collection)
        end
      end
    end
  end

  def remove_items(options)
    collection_items = collection_items_with_scope(options)
    count = 0
    collection_items.each do |item|
      item = CollectionItem.find(item) # Sometimes, this is just an id.
      if item.update_attribute(:collection_id, nil) # Not actually destroyed, so that we can talk about it in feeds.
        item.remove_collection_item_from_solr # TODO - needed?  Or does the #after_save method handle this?
        count += 1
        CollectionActivityLog.create(:collection => @collection, :user => current_user,
                                     :activity => Activity.remove, :collection_item => item)
      end
    end
    @collection_items.delete_if {|ci| collection_items.include?(ci.id.to_s) } if @collection_items
    return count
  end

  def collection_items_with_scope(options)
    collection_items = []
    if params[:scope].nil? || params[:scope] == 'selected_items'
      collection_items = options[:items]
    elsif params[:scope] == 'all_items'
      collection_items = options[:from].collection_items
    else # It's a particular type of item.
      collection_items = options[:from].items_from_solr(:facet_type => params[:scope], :page => 1, :per_page => 20000).map { |i| i['instance'] }
    end
    collection_items
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

  def link_to_name(collection)
    self.class.helpers.link_to(collection.name, collection_path(collection))
  end

  def set_edit_vars
    set_sort_options
    @site_column_id = 'collections_edit'
    @site_column_class = 'copy' # TODO - why?! (This was a HR thing.)
    @editing = true # TODO - there's a more elegant way to handle the difference in the layout...
    @head_title = I18n.t(:edit_collection_head_title, :collection_name => @collection.name) unless @collection.blank?
  end
  
  def set_sort_options
    @sort_options = [SortStyle.newest, SortStyle.oldest, SortStyle.alphabetical, SortStyle.reverse_alphabetical, SortStyle.richness, SortStyle.rating]
  end

end
