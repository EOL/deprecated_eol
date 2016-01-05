class CollectionItemsController < ApplicationController

  before_filter :allow_login_then_submit, only: [:create]
  before_filter :find_collection_item, only: [:show, :update, :edit]

  layout 'collections'

  def show
    return access_denied unless current_user.can_update?(@collection_item)
    @collection = @collection_item.collection # For layout
    @references = prepare_references
    respond_to do |format|
      format.html do
        @page_title = I18n.t(:collection_item_edit_page_title,
                             collection_name: @collection.name)
      end
      format.js { render partial: 'edit' }
    end
  end

  def create
    reset_errors
    if session[:submitted_data]
      create_from_submitted_data
    elsif params[:collection_id]
      create_from_collection_ids
    else
      create_collection_item(params[:collection_item])
    end
    update_errors

    respond_to do |format|
      format.html { redirect_to_taxon_or_curator }
      # coming from the overview page,
      format.js { render_collections_summary }
    end
  end

  def update
    # called when JS off
    return access_denied unless current_user.can_update?(@collection_item)
    update_collection_item || redirect_update_error
  end

  def edit
    respond_to do |format|
      format.js do
        if current_user.can_update?(@collection_item)
          @collection = @collection_item.collection
          @references = prepare_references
          render partial: 'collections/edit_collection_item',
            locals: { collection_item: @collection_item }
        else
          render text:
            I18n.t(:collection_item_edit_by_javascript_not_authorized_error)
        end
      end
    end
  end

  private

  def update_collection_item
    return false if
      CollectionItem.spammy?(params[:collection_item], current_user)
    return false unless @collection_item.
      update_attributes(params[:collection_item])
    update_collection_item_references
    respond_to do |format|
      format.html do
        flash[:notice] = I18n.t(:item_updated_in_collection_notice,
                           collection_name: @collection_item.collection.name)
        redirect_to(@collection_item.collection)
      end
      format.js do
        @collection = @collection_item.collection
        render partial: 'collection_items/show_editable_attributes',
          locals: { collection_item: @collection_item, item_editable: true }
      end
    end
  end

  def update_error
    respond_to do |format|
      format.html do
        flash[:error] = I18n.t(:item_not_updated_in_collection_error)
        redirect_to(@collection_item.collection)
      end
    end
  end

  def update_collection_item_references
    if @collection_item.collection.show_references?
      @collection_item.refs.clear
      @references = params[:references]
      unless params[:references].blank?
        params[:references] = params[:references].split("\n")
        params[:references].each do |reference|
          @collection_item.add_ref(reference)
        end
      end
    end
  end

  def prepare_references
    references = ''
    @collection_item.refs.each do |ref|
      references = references + "\n" unless references == ''
      references = references + ref.full_reference
    end
    references
  end

  def create_from_collection_ids
    Array(params[:collection_id]).each do |collection_id|
      create_collection_item(params[:collection_item].
                             merge(collection_id: collection_id))
    end
  end

  def create_from_submitted_data
    # They are coming back from logging in, data is stored:
    store_location(session[:submitted_data][:return_to])
    create_collection_item(session[:submitted_data][:collection_item])
    session.delete(:submitted_data)
  end

  def render_collections_summary
    if params[:render_overview_summary] &&
      @collection_item.collected_item.is_a?(TaxonConcept)
      if @errors.blank?
        @taxon_concept = TaxonConcept.
          find(@collection_item.collected_item_id)
        render partial: 'taxa/collections_summary', layout: false
      else
        render text: @errors.to_sentence
      end
    else
      convert_flash_messages_for_ajax
      render partial: 'shared/flash_messages',
        layout: false # JS will handle rendering these.
    end
  end

  def redirect_to_taxon_or_curator
    redirect_object = @collection_item.collected_item
    if redirect_object.is_a?(TaxonConcept)
      redirect_object = taxon_overview_url(redirect_object)
    end
    if redirect_object.is_a?(Curator)
      redirect_object = user_url(redirect_object)
    end
    redirect_to redirect_object, notice: flash[:notice]
  end

  def reset_errors
    # TODO: this will remove the duplicate Global Site Message
    # when collecting things. How can we better trap these cases?
    flash.now[:error] = nil
    @notices = []
    @errors = []
  end

  def update_errors
    flash.now[:errors] = @errors.to_sentence unless @errors.empty?
    flash[:notice] = @notices.to_sentence unless @notices.empty?
  end

  def find_collection_item
    @collection_item = CollectionItem.find(params[:id], include: [:collection])
    @selected_collection_items = []
    # To avoid errors.  If you edit something,
    # it becomes unchecked.  That's okay.
  end

  def create_collection_item(data)
    @collection_item = CollectionItem.new(data)
    @collection_item.collection ||=
      current_user.watch_collection unless current_user.blank?
    if @collection_item.collected_item_type == 'Collection' &&
      @collection_item.collected_item_id == @collection_item.collection.id
      @notices << I18n.t(:item_not_added_to_itself_notice,
                         collection_name: @collection_item.collection.name)
    elsif @collection_item.save
      CollectionActivityLog.create(collection: @collection_item.collection,
                                   user: current_user,
                                   activity: Activity.collect,
                                   collection_item: @collection_item)
      @collection_item.collection.updated_at = Time.now.to_s
      @collection_item.collection.save
      @notices << I18n.t(:item_added_to_collection_notice,
                         collection_name: self.class.helpers.
                           link_to(@collection_item.collection.name,
                                  collection_path(@collection_item.collection)))
    else
      # TODO: Ideally examine validation error and
      #provide more informative error message, e.g. item is
      # already in the collection etc
      @errors << I18n.t(:item_not_added_to_collection_error)
    end
  end

end
