# NOTE - we use these commit_* button names because we don't want to parse the I18n of the button name (hard).
class CollectionsController < ApplicationController

  # TODO - review these. There are too many and as a result there's some redundancy in, for example, checking whether the user is logged in on unpublished
  # collections
  before_filter :login_with_open_authentication, only: :show
  before_filter :modal, only: [:choose_editor_target, :choose_collect_target]
  before_filter :find_collection, except: [:new, :create, :choose_editor_target, :choose_collect_target, :cache_inaturalist_projects, :get_uri_name, :get_name]
  before_filter :prepare_show, only: [:show]
  before_filter :user_able_to_edit_collection, only: [:edit, :destroy] # authentication of update in the method
  before_filter :user_able_to_view_collection, only: [:show]
  before_filter :find_parent, only: [:show]
  before_filter :find_parent_for_current_user_only,
    except: [:show, :collect, :watch, :choose_editor_target, :choose_collect_target, :cache_inaturalist_projects]
  before_filter :configure_sorting_and_filtering_and_facet_counts, only: [:show, :update]
  before_filter :build_collection_items, only: [:show]
  before_filter :load_item, only: [:choose_editor_target, :choose_collect_target, :create]
  before_filter :restrict_to_admins, only: :reindex

  layout 'collections'

  RECORDS_PER_PAGE = 30

  def show
    # TODO - this line should be somewhere else:
    return copy_items_and_redirect(@collection, [current_user.watch_collection]) if params[:commit_collect]
    @collection_job = CollectionJob.new(collection: @collection)
    if @collection_results && @collection_results.is_a?(WillPaginate::Collection)
      set_canonical_urls(for: @collection, paginated: @collection_results, url_method: :collection_url)
      # TODO - this is... expensive, yeah?  Should we REALLY be doing this every time we show a page of a collection?!
      reindex_items_if_necessary(@collection_results)
    else
      @rel_canonical_href = collection_url(@collection)
    end
    respond_to do |format|
      format.html {}
      format.json { render json: @collection.as_json().merge(collection_items: @collection_items.map {|i|
          i.collected_item.as_json.merge(type: i.class.name)} ) }
    end
  end

  # NOTE - I COULD check the collection size against Collection::REINDEX_LIMIT, but I'd actually like to (personally) be able to
  # call the URL on large collections. Soooo... for me, it's enough that the link doesn't show up. That'll keep people from using
  # it unless they want to "force" it by faking the URL (which is, admittedly, easy, but I think that's fair).
  def reindex
    collection = Collection.find(params[:id])
    EOL::Solr::CollectionItemsCoreRebuilder.reindex_collection(collection)
    collection.update_attribute(:collection_items_count,
      collection.collection_items.count)
    redirect_to collection, notice: I18n.t(:collection_redindexed)
  end

  def new
    @page_title = I18n.t(:create_a_collection)
    @collection = Collection.new
  end

  def create
    return must_be_logged_in unless logged_in?
    @collection = Collection.new(params[:collection])
    if @collection.description =~ EOL.spam_re or
      @collection.name =~ EOL.spam_re and
      current_user.newish?
      flash[:error] = I18n.t(:error_violates_tos)
      return redirect_to request.referer
    end
    if @collection.save
      @collection.users = [current_user]
      log_activity(activity: Activity.create)
      flash[:notice] = I18n.t(:collection_created_with_count_notice,
                              collection_name: link_to_name(@collection),
                              count: @collection.collection_items.count)
      if params[:source_collection_id] # We got here by creating a new collection FROM an existing collection:
        return create_collection_from_existing
      else
        auto_collect(@collection)
        return create_collection_from_item
      end
    else
      flash[:error] = I18n.t(:collection_not_created_error, collection_name: @collection.name)
      return redirect_to request.referer
    end
    # You shouldn't get here; something weird happened.
    flash[:error] = I18n.t(:collection_not_created_error, collection_name: @collection.name)
    return redirect_to request.referer
  end

  def edit
    set_edit_vars
  end

  def update
    # TODO - These next two lines shouldn't be handled with a POST, they should be GETs (to #show):
    return redirect_to params.merge!(action: 'show').except(*unnecessary_keys_for_redirect) if params[:commit_sort]
    return redirect_to params.merge!(action: 'show').except(*unnecessary_keys_for_redirect) if params[:commit_view_as]
    return redirect_to_choose(:copy) if params[:commit_copy]
    # TODO - these should all go to collection_jobs_controller, now:
    return chosen if params[:scope] && params[:for] == 'copy'
    return remove_and_redirect if params[:commit_remove]
    return redirect_to_choose(:move) if params[:commit_move]

    # TODO - annotations need their own controller.
    # some of the following methods need the list of items on the page... I think.
    # if not, we should remove this as it is very expensive
    build_collection_items unless params[:commit_annotation]

    # copy is the only update action allowed for non-owners
    return if user_able_to_edit_collection # reads weird but will raise exception and exit if user cannot edit collection
    return annotate if params[:commit_annotation]
    return chosen if params[:scope] # Note that updating the collection params doesn't specify a scope.

    # TODO - This is really the only stuff that needs to stay here!
    name_change = params[:collection][:name] != @collection.name
    description_change = params[:collection][:description] != @collection.description
    if params[:collection][:description] =~ EOL.spam_re or
      params[:collection][:name] =~ EOL.spam_re and
      current_user.newish?
      flash[:error] = I18n.t(:error_violates_tos)
      return render(action: :edit)
    end
    if @collection.update_attributes(params[:collection])
      upload_logo(
        @collection,
        name: params[:collection][:logo].original_filename
      ) unless params[:collection][:logo].blank?
      # NOTE - when we sort, we don't *actually* update params...
      flash[:notice] =
        I18n.t(:collection_updated_notice, collection_name: @collection.name) if
        params[:collection]
      CollectionActivityLog.create({
        collection: @collection,
        user_id: current_user.id,
        activity: Activity.change_name
      }) if name_change
      CollectionActivityLog.create({
        collection: @collection,
        user_id: current_user.id,
        activity: Activity.change_description
      }) if description_change
      redirect_to(params.merge!(action: 'show').
        except(*unnecessary_keys_for_redirect), status: :moved_permanently)
    else
      set_edit_vars
      render action: :edit
    end
  end

  def destroy
    if @collection.special? || @collection.communities.count == 1
      flash[:error] = @collection.watch_collection? ?
        I18n.t(:watch_collections_cannot_be_destroyed) :
        I18n.t(:special_collections_cannot_be_destroyed)
      return redirect_to collection_url(@collection)
    else
      back = @collection.communities.first ?
        collection_url(@collection.communities.first) :
        user_collections_url(current_user)
      if @collection.unpublish
        flash[:notice] = I18n.t(:collection_destroyed)
      else
        flash[:error] = I18n.t(:collection_not_destroyed_error)
      end
      respond_to do |format|
        format.html { redirect_to(back, status: :moved_permanently) }
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
      @items = collection_items_with_scope(from: @collection, items: params[:collection_items], scope: @scope)
      # Helps identify where ONE item is in other collections...
      @item = CollectionItem.find(@items.first).collected_item if
        @items.length == 1
    rescue EOL::Exceptions::MaxCollectionItemsExceeded
      flash[:error] = I18n.t(:max_collection_items_error, max: $MAX_COLLECTION_ITEMS_TO_MANIPULATE)
      redirect_to collection_path(@collection), status: :moved_permanently
    end
    @collections = current_user.all_collections
    Collection.preload_associations(@collections, [ :communities, :resource, :resource_preview ])
    @collections.delete_if{ |c| c.is_resource_collection? }
    @page_title = I18n.t(:choose_collection_header)
  end

  # TODO - this should be its own controller (or possibly two with a shared view).
  # Either a user is passed in and we're making her a manager, or a community is passed in and we're "featuring" it.
  def choose_editor_target
    return must_be_logged_in unless logged_in?
    @user = User.find(params[:user_id]) rescue nil
    @sorts = {
      I18n.t(:sort_by_alphabetical_option) => :alpha,
      I18n.t(:sort_by_recently_updated_option) => :recent,
    }
    @community = Community.find(params[:community_id]) rescue nil
    @item = @user || @community # @item is for views, makes life easier.
    @collections = current_user.all_collections
    Collection.preload_associations(@collections, [ :resource, :resource_preview ])
    @collections.delete_if{ |c| c.is_resource_collection? || c.watch_collection? }
    @collections_recently_updated = @collections.sort_by(&:updated_at).reverse
    raise EOL::Exceptions::NoCollectionsApply if @collections.blank?
    @page_title = I18n.t(:make_user_an_editor_title, user: @item.summary_name)
    respond_to do |format|
      format.html { render 'choose_editor_target', layout: 'users' }
      format.js   { render partial: 'choose_editor_target' }
    end
  end

  def choose_collect_target
    return must_be_logged_in unless logged_in?
    @collections = current_user.all_collections || []
    @sorts = {
      I18n.t(:sort_by_alphabetical_option) => :alpha,
      I18n.t(:sort_by_recently_updated_option) => :recent,
    }
    Collection.preload_associations(@collections, [ :resource, :resource_preview ])
    @collections.delete_if { |c| c.is_resource_collection? }
    @collections_recently_updated = @collections.sort_by(&:updated_at).reverse
    raise EOL::Exceptions::ObjectNotFound unless @item
    @page_title = I18n.t(:collect_item) + " - " + @item.summary_name
    respond_to do |format|
      format.html do
        render 'choose_collect_target', layout: 'choose_collect_target'
      end
      format.js { render partial: 'choose_collect_target' }
    end
  end

  def choose_taxa_data
    return must_be_logged_in unless logged_in?
    taxon_items = []
    @collection.collection_items.taxa.each do |taxon_item|
      taxon_items += TaxonPage.new(TaxonConcept.find(taxon_item.collected_item_id)).data.get_data.data_point_uris
    end
    @taxon_collected_items = taxon_items.compact.uniq(&:predicate).paginate(page: params[:page], per_page: RECORDS_PER_PAGE)
    respond_to do |format|
      format.html { render 'choose_taxa_data'}
      format.js { render 'choose_taxa_data' }
    end
  end

  def download_taxa_data
    if params[:data_point_uri].blank?
      flash[:warning] = I18n.t("users.data_downloads.no_selected_attributes")
      return redirect_to params.merge(action: 'choose_taxa_data', collection: @collection)
    else
      Resque.enqueue(TaxaDownload, params[:data_point_uri], current_user.id, @collection.id)
      flash[:warning] = I18n.t("collections.download_taxa_data.collection_download_under_processing")
      redirect_to collection_path(@collection)
    end
  end

  #This maynot be the right place to put this. This method is used to get the name of the given uri from the KnownURIs.
  def get_name(uri)
    KnownUri.by_uri(uri).name
  end
  helper_method :get_name

  #This maynot be the right place to put this. This method is used to get the uri of the given data point uri id.
  def get_uri_name
    predicate = DataPointUri.find(params[:id]).predicate
    respond_to do |format|
      format.json { render json: {"uri" => predicate, "name" => KnownUri.by_uri(predicate).name}}
    end
  end

  def has_taxa?
    @collection.collection_items.taxa.any?
  end

  # TODO - this should really be its own resource in its own controller.
  def cache_inaturalist_projects
    InaturalistProjectInfo.cache_all if InaturalistProjectInfo.needs_caching?
    render nothing: true
  end

protected

  def scoped_variables_for_translations
    return @scoped_variables_for_translations if defined?(@scoped_variables_for_translations)
    @scoped_variables_for_translations = super.dup
    @scoped_variables_for_translations[:collection_name] = @collection ? @collection.name : nil
    if @collection
      if description = @collection.description.presence
        @scoped_variables_for_translations[:collection_description] = description
      else
        translation_vars_for_default_description = { collection_name: @collection.name,
                                                     scope: controller_action_scope,
                                                     default: '' }
        @scoped_variables_for_translations[:collection_description] = case @collection.special_collection_id
        when SpecialCollection.focus.id
          t(".meta_description_default_focus_collection", translation_vars_for_default_description.dup)
        when SpecialCollection.watch.id
          t(".meta_description_default_watch_collection", translation_vars_for_default_description.dup)
        else
          t(".meta_description_default", translation_vars_for_default_description.dup)
        end
      end
    else
      @scoped_variables_for_translations[:collection_description] = ''
    end
    @scoped_variables_for_translations.freeze
  end

  def meta_open_graph_image_url
    @meta_open_graph_image_url ||= @collection ?
      view_context.image_tag(@collection.logo_url(linked?: true)) : nil
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
      render action: 'unpublished'
      return false
    end
  end

  # When you're going to show a bunch of collection items and provide sorting and filtering capabilities:
  def configure_sorting_and_filtering_and_facet_counts
    set_view_as_options
    @view_as = params[:view_as].blank? ? @collection.view_style_or_default : ViewStyle.find(params[:view_as])
    set_sort_options
    @sort_by = params[:sort_by].blank? ? @collection.sort_style_or_default : SortStyle.find(params[:sort_by])
    @filter = params[:filter]
    @page = params[:page]
    @selected_collection_items = params[:collection_items] || []

    # NOTE - you still need these counts on the Update page:
    @facet_counts = EOL::Solr::CollectionItems.get_facet_counts(@collection.id)
  end

  # we don't need the collection items on the update page
  def build_collection_items
    @per_page = @view_as.max_items_per_page || 50
    @collection_results = @filter == 'editors' ?  [] :
      @collection.items_from_solr(facet_type: @filter, page: @page, sort_by: @sort_by,
        per_page: @per_page,view_style: @view_as, language_id: current_language.id)
    @collection_items = @collection_results.map { |i| i['instance'] }.compact
    if params[:commit_select_all]
      @selected_collection_items = @collection_items.map { |ci| ci.id.to_s }
    end
  end

  # When we bounce around, not all params are required; this is the list to remove:
  # NOTE - to use this as an parameter, you need to de-reference the array with a splat (*).
  def unnecessary_keys_for_redirect
    [:_method, :commit_sort, :commit_view_as, :commit_select_all, :commit_copy, :commit, :collection,
     :commit_move, :commit_remove, :commit_edit_collection, :commit_collect]
  end

  def no_items_selected_error(which)
    flash[:warning] = I18n.t("items_no_#{which}_none_selected_warning")
    return redirect_to params.merge(action: 'show').except(*unnecessary_keys_for_redirect)
  end

  def redirect_to_choose(for_what)
    if params[:scope] == 'selected_items'
      return no_items_selected_error(:copy) if params[:collection_items].nil? or params[:collection_items].empty?
    end
    return_to = request.referrer || collection_path(@collection)
    return redirect_to params.merge(action: 'choose', for: for_what, return_to: return_to).except(*unnecessary_keys_for_redirect)
  end

  def chosen
    case params[:for]
    when 'move'
      return copy_items_and_redirect(@collection, @collections, move: true)
    when 'copy'
      return copy_items_and_redirect(@collection, @collections)
    else
      if params[:action] == "update"
        # call for annotate
        return annotate
      else
        flash[:error] = I18n.t(:action_not_available_error)
        return redirect_to collection_path(@collection)
      end
    end
  end

  def copy_items_and_redirect(source, destinations, options = {})
    if params[:scope] == 'all_items'
      return quick_copy_entire_collection_and_redirect(source, destinations, options)
    else
      copied = {}
      @copied_to = []
      all_items = []
      Collection.preload_associations(destinations, :collection_items)
      params[:collection_items] = CollectionItem.find(params[:collection_items], include: :collected_item) if params[:collection_items]
      Collection.preload_associations(source, :users)
      destinations.each do |destination|
        begin
          items = copy_items(from: source, to: destination, items: params[:collection_items],
                             scope: params[:scope])
          copied[link_to_name(destination)] = items.count
          all_items += items
          # TODO - this rescue can cause SOME work to get done and others not.  It should be moved.
        rescue EOL::Exceptions::MaxCollectionItemsExceeded
          flash[:error] = I18n.t(:max_collection_items_error, max: $MAX_COLLECTION_ITEMS_TO_MANIPULATE)
          return redirect_to collection_path(@collection)
        end
      end
      all_items.compact!#.why_am_i_shouting!?
      flash_i18n_name = :copied_items_to_collections_with_count_notice
      if all_items.count > 0
        if options[:move]
          # Not handling any weird errors here, to simplify flash notice handling.
          remove_items(from: source, items: all_items)
          @collection_items.delete_if { |ci| params['collection_items'].include?(ci.id.to_s) } if @collection_items && params['collection_items']
          if destinations.length == 1
            flash[:notice] = I18n.t(:moved_items_from_collection_with_count_notice, count: all_items.count,
                                    name: link_to_name(source))
            flash[:notice] += " #{I18n.t(:duplicate_items_were_ignored)}" if @duplicates
            return redirect_to collection_path(destinations.first), status: :moved_permanently
          else
            flash_i18n_name = :moved_items_to_collections_with_count_notice
          end
        else
          if destinations.length == 1
            flash[:notice] = I18n.t(:copied_items_from_collection_with_count_notice, count: all_items.count,
                                    name: link_to_name(source))
            flash[:notice] += " #{I18n.t(:duplicate_items_were_ignored)}" if @duplicates
            return redirect_to collection_path(destinations.first), status: :moved_permanently
          end
        end
        flash[:notice] = I18n.t(flash_i18n_name,
                                count: all_items.count,
                                names: copied.keys.map { |c| "#{c} (#{copied[c]})"}.to_sentence)
        flash[:notice] += " #{I18n.t(:duplicate_items_were_ignored)}" if @duplicates
        return redirect_to collection_path(source), status: :moved_permanently
      elsif all_items.count == 0
        flash[:error] = I18n.t(:no_items_were_copied_to_collections_error, names: @no_items_to_collections.to_sentence)
        flash[:error] += " #{I18n.t(:duplicate_items_were_ignored)}" if @duplicates
        return redirect_to collection_path(source), status: :moved_permanently
      else
        # Assume the flash message was set by #copy_items
        return redirect_to collection_path(source), status: :moved_permanently
      end
    end
  end

  def quick_copy_entire_collection_and_redirect(source, destinations, options)
    last_collection_item = CollectionItem.last(select: 'id') # Sloppy, but...
    destinations.each do |destination|
      CollectionItem.connection.execute(
        "INSERT IGNORE INTO collection_items
          (collected_item_type, collected_item_id, collection_id, created_at, updated_at, added_by_user_id)
          (SELECT collected_item_type, collected_item_id, #{destination.id}, NOW(), NOW(), #{current_user.id}
            FROM collection_items WHERE collection_id = #{source.id})"
      )
      # Because we did it manually, the count (shown in searches) will be off, so fix it:
      destination.update_attribute(collection_items_count, destination.collection_items.count)
      # TODO - we should actually count the items and store that in the collection activity log. Lots of work:
      log_activity(collection_id: destination.id, activity: Activity.bulk_add)
    end
    ids = CollectionItem.connection.execute(
      "SELECT id FROM collection_items
       WHERE id > #{last_collection_item.id} AND collection_id IN (#{destinations.map { |d| d.id}.join(',')})"
    ).map { |a| a.first }
    EOL::Solr::CollectionItemsCoreRebuilder.reindex_collection_items_by_ids(ids)
    # NOTE - this is pretty brutal. The older method preserves objects that didn't actually move (ie: if they were
    # duplicates), but I figure that's not entirely desirable, anyway...
    action = options[:move] ? 'moved' : 'copied'
    if options[:move]
      if destinations.include?(source)
        action = 'copied' # Undo the "move"... we can't blow away the items in a source if it's a destination!
      else
        source.collection_items.each { |item| item.destroy }
        log_activity(activity: Activity.remove_all)
      end
    end
    if destinations.count == 1
      flash[:notice] = I18n.t("#{action}_all_items_from_collection_with_count", count: ids.count,
                              from: link_to_name(source))
      return redirect_to collection_path(destinations.first), status: :moved_permanently
    else
      flash[:notice] = I18n.t("#{action}_all_items_to_collections", count: destinations.count,
                              name: link_to_name(source))
      return redirect_to collection_path(source), status: :moved_permanently
    end
  end

  def copy_items(options)
    collection_items = collection_items_with_scope(options)
    copy_to_collection = options[:to]
    new_collection_items = []
    old_collection_items = []
    count = 0
    @duplicates = false
    collection_items = CollectionItem.find_all_by_id(collection_items)
    CollectionItem.preload_associations(collection_items, [ :collected_item, :collection ])
    collection_items.each do |collection_item|
      if copy_to_collection.has_item?(collection_item.collected_item)
        @duplicates = true
      else
        old_collection_items << collection_item
        # Some data may only be copied when the user has a right to edit them. This avoids some IP problems.
        # TODO: Add references to copiable items
        copiable = options[:from].editable_by?(current_user) ?
                     { annotation: collection_item.annotation,
                       sort_field: collection_item.sort_field } : {}
        new_collection_items << { collected_item_id: collection_item.collected_item.id,
                                  collected_item_type: collection_item.collected_item_type,
                                  added_by_user_id: current_user.id }.merge!(copiable)
        count += 1
        # TODO - gak.  This points to the wrong collection item and needs to be moved to AFTER the save:
        log_activity(collection: options[:to], activity: Activity.collect, collection_item: collection_item)
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
                             name: link_to_name(options[:to]))].compact.join(" ")
    end
  end

  def remove_and_redirect
    begin
      count = remove_items(from: @collection, items: params[:collection_items], scope: params[:scope])
    rescue EOL::Exceptions::NoItemsSelected
      flash[:error] = I18n.t(:collection_error_no_items_selected)
      return redirect_to collection_path(@collection), status: :moved_permanently
    rescue EOL::Exceptions::MaxCollectionItemsExceeded
      flash[:error] = I18n.t(:max_collection_items_error, max: $MAX_COLLECTION_ITEMS_TO_MANIPULATE)
      return redirect_to collection_path(@collection), status: :moved_permanently
    end
    flash[:notice] = I18n.t(:removed_count_items_from_collection_notice, count: count)
    return redirect_to collection_path(@collection), status: :moved_permanently
  end

  def annotate
    Collection.with_master do
      Collection.uncached do
        if @collection.update_attributes(params[:collection])
          @collection_item = CollectionItem.find(params[:collection][:collection_items_attributes].keys.map { |i|
                params[:collection][:collection_items_attributes][i][:id] }.first)
          if @collection.show_references
            @collection_item.refs.clear
            unless params[:references].blank?
              params[:references].split("\n").each do |original_ref|
                reference = original_ref.strip
                unless reference.blank?
                  ref = Ref.find_or_create_by_full_reference_and_user_submitted_and_published_and_visibility_id(reference, 1, 1, Visibility.get_visible.id)
                  @collection_item.refs << ref
                  @collection_item.save!
                end
              end
            end
          end
          respond_to do |format|
            format.js do
              render partial: 'collection_items/show_editable_attributes',
                locals: { collection_item: @collection_item, item_editable: true }
            end
          end
        else
          respond_to do |format|
            format.js { render text: I18n.t(:item_not_updated_in_collection_error) }
            format.html do
              flash[:error] = I18n.t(:item_not_updated_in_collection_error)
              redirect_to @collection
            end
          end
        end
      end
    end
  end

  def remove_items(options)
    collection_items = options[:items] || collection_items_with_scope(options.merge(allow_all: true))
    all_items = params[:scope] == 'all_items'
    count = 0
    raise EOL::Exceptions::NoItemsSelected if collection_items.blank?
    if all_items
      @collection.clear
      log_activity(activity: Activity.remove_all)
    else
      collection_items.each do |item|
        item = CollectionItem.find(item) # Sometimes, this is just an id.
        if item.update_attributes(collection_id: nil) # Not actually destroyed, so that we can talk about it in feeds.
          item.remove_from_solr # TODO - needed?  Or does the #after_save method handle this?
          count += 1
          log_activity(activity: Activity.remove, collection_item: item)
        end
      end
      @collection_items.delete_if { |ci| collection_items.include?(ci.id.to_s) } if @collection_items
    end
    options[:from].set_relevance if options[:from]
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
      results = options[:from].items_from_solr(facet_type: params[:scope], page: 1,
                                               per_page: $MAX_COLLECTION_ITEMS_TO_MANIPULATE)
      collection_items = results.map { |i| i['instance'] }
    end
    collection_items
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

  def link_to_name(collection)
    self.class.helpers.link_to(collection.name, collection_path(collection))
  end

  def set_edit_vars
    set_sort_options
    set_view_as_options
    @site_column_id = 'collections_edit'
    @site_column_class = 'copy' # TODO - why?! (This was a HR thing.)
    @editing = true # TODO - there's a more elegant way to handle the difference in the layout...
  end

  def set_sort_options
    @sort_options = [ SortStyle.newest, SortStyle.oldest, SortStyle.alphabetical, SortStyle.reverse_alphabetical,
                      SortStyle.richness, SortStyle.rating, SortStyle.sort_field, SortStyle.reverse_sort_field ]
  end

  def set_view_as_options
    @view_as_options = [ViewStyle.list, ViewStyle.gallery, ViewStyle.annotated]
  end

  def user_able_to_view_collection
    unless @collection && current_user.can_read?(@collection)
      if logged_in?

        raise EOL::Exceptions::SecurityViolation.new("User with ID=#{current_user.id} does not have read access to Collection with ID=#{@collection.id}",
        :admins_and_joined_only_can_read)
      else
        raise EOL::Exceptions::MustBeLoggedIn, "Non-authenticated user does not have read access to Collection with id=#{@collection.id}"
      end
      return true
    end
  end

  def user_able_to_edit_collection
    unless @collection && current_user.can_edit_collection?(@collection)
      if logged_in?

        raise EOL::Exceptions::SecurityViolation.new("User with ID=#{current_user.id} does not have edit access to Collection with ID=#{@collection.id}",
        :owner_and_managers_only_can_edit)
      else
        raise EOL::Exceptions::MustBeLoggedIn, "Non-authenticated user does not have edit access to Collection with id=#{@collection.id}"
      end
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
      log_activity(activity: Activity.create)
      return copy_items_and_redirect(source, [@collection])
    elsif params[:for] == 'move'
      auto_collect(@collection)
      EOL::GlobalStatistics.increment('collections')
      log_activity(activity: Activity.create)
      return copy_items_and_redirect(source, [@collection], move: true)
    else
      @collection.destroy
      flash[:notice] = nil # We're undoing the create.
      flash[:error] = I18n.t(:collection_not_created_error, collection_name: @collection.name)
      return redirect_to collection_path(@collection)
    end
  end

  def create_collection_from_item
    @collection.add(@item)
    EOL::GlobalStatistics.increment('collections')
    flash[:notice] = I18n.t(:collection_created_notice, collection_name: link_to_name(@collection))
    respond_to do |format|
      format.html { redirect_to link_to_item(@item), status: :moved_permanently }
      format.js do
        convert_flash_messages_for_ajax
        render partial: 'shared/flash_messages', layout: false
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

  # These are things that ALL three collections controllers will need, so:
  def prepare_show
    @page = params[:page] || 1
    types = CollectionItem.types
    @collection_item_scopes = [[I18n.t(:selected_items), :selected_items], [I18n.t(:all_items), :all_items]]
    @collection_item_scopes << [I18n.t("all_#{types[@filter.to_sym][:i18n_key]}"), @filter] if @filter
    @recently_visited_collections = Collection.find_all_by_id(recently_visited_collections(@collection.id)) if @collection
  end

  def log_activity(options = {})
    CollectionActivityLog.create(options.reverse_merge(collection: @collection, user: current_user))
  end

  # NOTE - object_type and object_id not changed due yet; they are stale names in Solr.
  def reindex_items_if_necessary(collection_results)
    collection_item_ids_to_reindex = []
    collection_results.each do |r|
      # the instance should never be nil, but sometimes it is when the DB and Solr are out of sync
      next if r['instance'].nil?
      if !(r['sort_field'].blank? && r['instance'].sort_field.blank?) && r['sort_field'] != r['instance'].sort_field
        collection_item_ids_to_reindex << r['instance'].id
      elsif r['object_type'] == 'TaxonConcept'
        entry = r['instance'].collected_item.entry
        # The taxon didn't have a prefferred entry:
        entry ||= r['instance'].collected_item.reload.entry
        # this is the same way we get names when indexing collection items, so be consistent
        title = entry.name.string
        if title && r['title'] != SolrAPI.text_filter(title)
          collection_item_ids_to_reindex << r['instance'].id
        elsif r['instance'].collected_item.taxon_concept_metric && r['richness_score'] != r['instance'].collected_item.taxon_concept_metric.richness_score
          collection_item_ids_to_reindex << r['instance'].id
        end
      elsif ['Text', 'Image', 'DataObject', 'Video', 'Sound', 'Link', 'Map'].include?(r['object_type'])
        if r['data_rating'] != r['instance'].collected_item.data_rating
          collection_item_ids_to_reindex << r['instance'].id
        end
      end
    end
    EOL::Solr::CollectionItemsCoreRebuilder.reindex_collection_items_by_ids(collection_item_ids_to_reindex.uniq)
  end

end
