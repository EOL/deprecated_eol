# A bit tricky.
#
# You could come here looking at a Community's Collection.
# You could come here looking at a (specified) User's Collection. (show only)
#     UPDATE: user collections index is now in users/collections
# And you could come here without either of those (implying the current_user's Collection).
#
# NOTE - we use these commit_* button names because we don't want to parse the I18n of the button name (hard).
class CollectionsController < ApplicationController

  before_filter :modal, :only => [:choose_collect_target]
  before_filter :find_collection, :except => [:new, :create, :choose_collect_target]
  before_filter :user_able_to_edit_collection, :only => [:edit, :destroy] # authentication of update in the method
  before_filter :user_able_to_view_collection, :only => [:show]
  before_filter :find_parent, :only => [:show]
  before_filter :find_parent_for_current_user_only, :except => [:show, :collect, :watch, :choose_collect_target]
  before_filter :build_collection_items_with_sorting_and_filtering, :only => [:show, :update]
  before_filter :load_item, :only => [:choose_collect_target, :create]

  layout 'v2/collections'

  def show
    @page = params[:page] || 1
    render :action => 'newsfeed' if @filter == 'newsfeed'
    return copy_items_and_redirect(@collection, [current_user.watch_collection]) if params[:commit_collect]
    types = CollectionItem.types
    @collection_item_scopes = [[I18n.t(:selected_items), :selected_items], [I18n.t(:all_items), :all_items]]
    @collection_item_scopes << [I18n.t("all_#{types[@filter.to_sym][:i18n_key]}"), @filter] if @filter
  end

  def new
    @page_title = I18n.t(:create_a_collection)
    @collection = Collection.new
  end

  def create    
    @collection = Collection.new(params[:collection])
    if @collection.save
      flash[:notice] = I18n.t(:collection_created_with_count_notice,
                              :collection_name => link_to_name(@collection),
                              :count => @collection.collection_items.count)
      if params[:source_collection_id] # We got here by creating a new collection FROM an existing collection:
        return create_collection_from_existing
      else
        auto_collect(@collection)
        return create_collection_from_item
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
    return redirect_to params.merge!(:action => 'show').except(*unnecessary_keys_for_redirect) if params[:commit_sort]
    return redirect_to_choose(:copy) if params[:commit_copy]
    return chosen if params[:scope] && params[:for] == 'copy'
    # copy is the only update action allowed for non-owners
    return if user_able_to_edit_collection
    return redirect_to_choose(:move) if params[:commit_move]
    return remove_and_redirect if params[:commit_remove]
    return chosen if params[:scope] # Note that updating the collection params doesn't specify a scope.
    return annotate if params[:commit_annotation]
    if @collection.update_attributes(params[:collection])
      upload_logo(@collection) unless params[:collection][:logo].blank?
      flash[:notice] = I18n.t(:collection_updated_notice, :collection_name => @collection.name) if
        params[:collection] # NOTE - when we sort, we don't *actually* update params...
      redirect_to params.merge!(:action => 'show').except(*unnecessary_keys_for_redirect)
    else
      set_edit_vars
      render :action => :edit
    end
  end

  def destroy
    if @collection.special? || @collection.community_id
      flash[:error] = I18n.t(:special_collections_cannot_be_destroyed)
      return redirect_to collection_url(@collection)
    else
      back = @collection.user ? user_collections_url(current_user) : collection_url(@collection.community)
      if @collection.update_attributes(:published => false)
        EOL::GlobalStatistics.decrement('collections')
        flash[:notice] = I18n.t(:collection_destroyed)
      else
        flash[:error] = I18n.t(:collection_not_destroyed_error)
      end
      respond_to do |format|
        format.html { redirect_to(back) }
        format.xml  { head :ok }
      end
    end
  end

  # /collections/choose GET
  def choose
    @site_column_id = 'collections_choose'
    @selected_collection_items = params[:collection_items]
    @for   = params[:for]
    @scope = params[:scope]
    # Annoying that we have to do this to get the count, but it really does help to have it!:
    begin
      @items = collection_items_with_scope(:from => @collection, :items => params[:collection_items], :scope => @scope)
      # Helps identify where ONE item is in other collections...
      @item = CollectionItem.find(@items.first).object if
        @items.length == 1
    rescue EOL::Exceptions::MaxCollectionItemsExceeded
      flash[:error] = I18n.t(:max_collection_items_error, :max => $MAX_COLLECTION_ITEMS_TO_MANIPULATE)
      redirect_to collection_path(@collection)
    end
    @collections = current_user.all_collections.delete_if{ |c| c.is_resource_collection? }
    @page_title = I18n.t(:choose_collection_header)
  end

  def choose_collect_target
    return must_be_logged_in unless logged_in?
    @collections = current_user.all_collections.delete_if{ |c| c.is_resource_collection? }
    return EOL::Exceptions::ObjectNotFound unless @item
    @page_title = I18n.t(:collect_item) + " - " + @item.summary_name
    respond_to do |format|
      format.html do
        # We want to show a "summary" of the object, using it's appropriate layout:
        use_layout = case params[:item_type]
                     when 'DataObject'
                       @data_object = @item
                       'v2/data'
                     when 'User'
                       @user = @item
                       'v2/users'
                     when 'Community'
                       @community = @item
                       'v2/collections'
                     when 'TaxonConcept'
                       @taxon_concept = @item
                       'v2/taxa'
                     when 'Collection'
                       @collection = @item
                       'v2/collections'
                     end
        render :partial => 'choose_collect_target', :layout => use_layout
      end
      format.js { render :partial => 'choose_collect_target' }
    end
  end

private

  def find_collection
    begin
      if params[:collection_id] && params[:collection_id].is_a?(Array)
        @collections = Collection.find(params[:collection_id]) # target collections for move/copy
        @collection = Collection.find(params[:id])
      else
        @collection = Collection.find(params[:collection_id] || params[:id])
      end
    rescue ActiveRecord::RecordNotFound
      flash[:error] = I18n.t(:collection_not_found_error)
      return redirect_back_or_default
    end
    unless @collection.published? || @collection.resource_preview
      render :action => 'unpublished'
      return false
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
    case params[:for]
    when 'move'
      return copy_items_and_redirect(@collection, @collections, :move => true)
    when 'copy'
      return copy_items_and_redirect(@collection, @collections)
    else
      flash[:error] = I18n.t(:action_not_available_error)
      return redirect_to collection_path(@collection)
    end
  end

  def copy_items_and_redirect(source, destinations, options = {})
    copied = {}
    @copied_to = []
    all_items = []
    destinations.each do |destination|
      begin
        items = copy_items(:from => source, :to => destination, :items => params[:collection_items],
                           :scope => params[:scope])
        copied[link_to_name(destination)] = items.count
        all_items += items
        # TODO - this rescue can cause SOME work to get done and others not.  It should be moved.
      rescue EOL::Exceptions::MaxCollectionItemsExceeded
        flash[:error] = I18n.t(:max_collection_items_error, :max => $MAX_COLLECTION_ITEMS_TO_MANIPULATE)
        return redirect_to collection_path(@collection)
      end
    end
    all_items.compact!#.why_am_i_shouting!?
    flash_i18n_name = :copied_items_to_collections_with_count_notice
    if all_items.count > 0
      if options[:move]
        # Not handling any weird errors here, to simplify flash notice handling.
        remove_items(:items => all_items)
        @collection_items.delete_if {|ci| params['collection_items'].include?(ci.id.to_s) } if @collection_items && params['collection_items']
        if destinations.length == 1
          flash[:notice] = I18n.t(:moved_items_from_collection_with_count_notice, :count => all_items.count,
                                  :name => link_to_name(source))
          flash[:notice] += " #{I18n.t(:duplicate_items_were_ignored)}" if @duplicates
          return redirect_to collection_path(destinations.first)
        else
          flash_i18n_name = :moved_items_to_collections_with_count_notice
        end
      else
        if destinations.length == 1
          flash[:notice] = I18n.t(:copied_items_from_collection_with_count_notice, :count => all_items.count,
                                  :name => link_to_name(source))
          flash[:notice] += " #{I18n.t(:duplicate_items_were_ignored)}" if @duplicates
          return redirect_to collection_path(destinations.first)
        end
      end
      flash[:notice] = I18n.t(flash_i18n_name,
                              :count => all_items.count,
                              :names => copied.keys.map {|c| "#{c} (#{copied[c]})"}.to_sentence)
      flash[:notice] += " #{I18n.t(:duplicate_items_were_ignored)}" if @duplicates
      return redirect_to collection_path(source)
    elsif all_items.count == 0
      flash[:error] = I18n.t(:no_items_were_copied_to_collections_error, :names => @no_items_to_collections.to_sentence)
      flash[:error] += " #{I18n.t(:duplicate_items_were_ignored)}" if @duplicates
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
    old_collection_items = []
    count = 0
    @duplicates = false
    collection_items.each do |collection_item|
      collection_item = CollectionItem.find(collection_item) # sometimes this is just an id.
      if already_have.include?([collection_item.object.id, collection_item.object_type])
        @duplicates = true
      else
        old_collection_items << collection_item
        # Annotations may only be copied when the user has a right to edit them. This avoids some IP problems.
        annotate = options[:from].editable_by?(current_user) ? collection_item.annotation : nil
        new_collection_items << { :object_id => collection_item.object.id,
                                  :object_type => collection_item.object_type,
                                  :annotation => annotate,
                                  :added_by_user_id => current_user.id }
        count += 1
        # TODO - gak.  This points to the wrong collection item and needs to be moved to AFTER the save:
        CollectionActivityLog.create(:collection => options[:to], :user => current_user,
                                     :activity => Activity.collect, :collection_item => collection_item)
      end
    end
    if new_collection_items.empty?
      @no_items_to_collections ||= []
      @no_items_to_collections << link_to_name(options[:to])
      return([])
    end
    options[:to].collection_items_attributes = new_collection_items
    if options[:to].save
      options[:to].set_relevance
      return old_collection_items
    else
      [flash[:error], I18n.t(:unable_to_copy_items_to_collection_error,
                             :name => link_to_name(options[:to]))].compact.join(" ")
    end
  end

  def remove_and_redirect
    begin
      count = remove_items(:from => @collection, :items => params[:collection_items], :scope => params[:scope])
    rescue EOL::Exceptions::MaxCollectionItemsExceeded
      flash[:error] = I18n.t(:max_collection_items_error, :max => $MAX_COLLECTION_ITEMS_TO_MANIPULATE)
      return redirect_to collection_path(@collection)
    end
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
    collection_items = options[:items] || collection_items_with_scope(options.merge(:allow_all => true))
    bulk_log = params[:scope] == 'all_items'
    count = 0
    removed_from_id = 0
    collection_items.each do |item|
      item = CollectionItem.find(item) # Sometimes, this is just an id.
      removed_from_id = item.collection_id
      if item.update_attributes(:collection_id => nil) # Not actually destroyed, so that we can talk about it in feeds.
        item.remove_collection_item_from_solr # TODO - needed?  Or does the #after_save method handle this?
        count += 1
        unless bulk_log
          CollectionActivityLog.create(:collection_id => removed_from_id, :user => current_user,
                                       :activity => Activity.remove, :collection_item => item)
        end
      end
    end
    @collection_items.delete_if {|ci| collection_items.include?(ci.id.to_s) } if @collection_items
    if bulk_log
      CollectionActivityLog.create(:collection => @collection, :user => current_user, :activity => Activity.remove_all)
    end
    # Recalculate the collection's relevance (quietly):
    (col = Collection.find(removed_from_id)) && col.set_relevance
    return count
  end

  def collection_items_with_scope(options)
    collection_items = []
    if params[:scope].nil? || params[:scope] == 'selected_items'
      collection_items = options[:items] # NOTE - no limit, since these are HTML parms, which are limited already.
    elsif params[:scope] == 'all_items'
      raise EOL::Exceptions::MaxCollectionItemsExceeded if
        options[:from].collection_items.count > $MAX_COLLECTION_ITEMS_TO_MANIPULATE && ! options[:allow_all]
      collection_items = options[:from].collection_items
    else # It's a particular type of item.
      count = options[:from].facet_count(CollectionItem.types[params[:scope].to_sym][:facet])
      raise EOL::Exceptions::MaxCollectionItemsExceeded if count > $MAX_COLLECTION_ITEMS_TO_MANIPULATE
      results = options[:from].items_from_solr(:facet_type => params[:scope], :page => 1,
                                               :per_page   => $MAX_COLLECTION_ITEMS_TO_MANIPULATE)
      collection_items = results.map { |i| i['instance'] }
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

  def user_able_to_view_collection
    unless @collection && current_user.can_view_collection?(@collection)
      access_denied
      return true
    end
  end

  def user_able_to_edit_collection
    unless @collection && current_user.can_edit_collection?(@collection)
      access_denied
      return true
    end
  end

  def create_collection_from_existing
    source = Collection.find(params[:source_collection_id])
    if source.nil?
      @collection.destroy
      flash[:notice] = nil # We're undoing the create.
      flash[:error] = I18n.t(:could_not_find_collection_error)
      return redirect_to collection_path(@collection)
    end
    if params[:for] == 'copy'
      auto_collect(@collection)
      EOL::GlobalStatistics.increment('collections')
      CollectionActivityLog.create(:collection => @collection, :user => current_user, :activity => Activity.create)
      return copy_items_and_redirect(source, [@collection])
    elsif params[:for] == 'move'
      auto_collect(@collection)
      EOL::GlobalStatistics.increment('collections')
      CollectionActivityLog.create(:collection => @collection, :user => current_user, :activity => Activity.create)
      return copy_items_and_redirect(source, [@collection], :move => true)
    else
      @collection.destroy
      flash[:notice] = nil # We're undoing the create.
      flash[:error] = I18n.t(:collection_not_created_error, :collection_name => @collection.name)
      return redirect_to collection_path(@collection)
    end
  end

  def create_collection_from_item    
    @collection.add(@item)
    EOL::GlobalStatistics.increment('collections')
    flash[:notice] = I18n.t(:collection_created_notice, :collection_name => link_to_name(@collection))
    respond_to do |format|
      format.html { redirect_to link_to_item(@item) }
      format.js do
        convert_flash_messages_for_ajax
        render :partial => 'shared/flash_messages', :layout => false
      end
    end
  end

  def load_item
    if params[:item_type] && params[:item_id]
      case params[:item_type]
      when 'DataObject'
        @item = DataObject.find(params[:item_id])
      when 'TaxonConcept'
        @item = TaxonConcept.find(params[:item_id])
      when 'User'
        @item = User.find(params[:item_id])
      when 'Community'
        @item = Community.find(params[:item_id])
      when 'Collection'
        @item = Collection.find(params[:item_id])
      else
        raise EOL::Exceptions::ObjectNotFound
      end
    end
  end

  def modal
    @modal = true # When this is JS, we need a "go back" link at the bottom if there's an error, and this needs
                  # to be set super-early!
  end

end
