class CollectionItemsController < ApplicationController

  before_filter :allow_login_then_submit, :only => [:create]
  before_filter :find_collection_item, :only => [:show, :update, :edit]

  layout 'v2/collections'

  def show
    return access_denied unless current_user.can_update?(@collection_item)
    @collection = @collection_item.collection # For layout
    @references = ''
    @collection_item.refs.each do |ref|
      @references = @references + "\n" unless @references==''
      @references = @references + ref.full_reference
    end
    respond_to do |format|
      format.html do
        @page_title = I18n.t(:collection_item_edit_page_title, :collection_name => @collection.name)
      end
      format.js { render :partial => 'edit' }
    end
  end

  # POST /collection_items
  def create
    # TODO: this will remove the duplicate Global Site Message when collecting things. How can we better trap these cases?
    flash.now[:error] = nil
    @notices = []
    @errors = []
    # Sooo... we could get our data in a lot of different ways.
    if session[:submitted_data] # They are coming back from logging in, data is stored:
      store_location(session[:submitted_data][:return_to])
      create_collection_item(session[:submitted_data][:collection_item])
      session.delete(:submitted_data)
    elsif params[:collection_id] # They are collecting to MULTIPLE collections (potentially):
      if params[:collection_id].is_a? Array
        params[:collection_id].each do |collection_id|
          create_collection_item(params[:collection_item].merge(:collection_id => collection_id))
        end
      else
        create_collection_item(params[:collection_item].merge(:collection_id => params[:collection_id]))
      end
    else # ...or this is just a simple single collect:
      create_collection_item(params[:collection_item])
    end
    flash.now[:errors] = @errors.to_sentence unless @errors.empty?
    flash[:notice] = @notices.to_sentence unless @notices.empty?
    
    respond_to do |format|
      format.html do
        redirect_object = @collection_item.collected_item
        if redirect_object.is_a?(TaxonConcept)
          redirect_object = taxon_overview_url(redirect_object)
        end
        if redirect_object.is_a?(Curator)
          redirect_object = user_url(redirect_object)
        end
        redirect_to redirect_object
      end
      format.js do
        # this means we came from the collections summary on the overview page,
        # so render that entire summary box again
        if params[:render_overview_summary] && @collection_item.collected_item.is_a?(TaxonConcept)
          if @errors.blank?
            @taxon_concept = TaxonConcept.find(@collection_item.collected_item_id)
            render :partial => 'taxa/collections_summary', :layout => false
          else
            render :text => @errors.to_sentence
          end
        else
          convert_flash_messages_for_ajax
          render :partial => 'shared/flash_messages', :layout => false # JS will handle rendering these.
        end
      end
    end
  end

  # PUT /collection_items/:id
  def update
    # Update method is called when JS off by submit of /collection_items/:id/edit. When JS is on collection item
    # updates are handled by the Collections update method and specifically the annotate method in Collections controller.
    return access_denied unless current_user.can_update?(@collection_item)
    if @collection_item.update_attributes(params[:collection_item])
      # update collection item references
      if @collection_item.collection.show_references?
        @collection_item.refs.clear
        @references = params[:references]
        params[:references] = params[:references].split("\n") unless params[:references].blank?
        unless params[:references].blank?
          params[:references].each do |reference|
            if reference.strip != ''
              ref = Ref.find_by_full_reference_and_user_submitted_and_published_and_visibility_id(reference, 1, 1, Visibility.visible.id)
              if (ref)
                @collection_item.refs << ref
              else
                @collection_item.refs << Ref.new(:full_reference => reference, :user_submitted => true, :published => 1, :visibility => Visibility.visible)
              end
            end
          end
        end
      end
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:item_updated_in_collection_notice, :collection_name => @collection_item.collection.name)
          redirect_to(@collection_item.collection)
        end
        format.js do
          @collection = @collection_item.collection # Need to know whether refs are shown...
          render partial: 'collection_items/show_editable_attributes',
            locals: { collection_item: @collection_item, item_editable: true }
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = I18n.t(:item_not_updated_in_collection_error)
          redirect_to(@collection_item.collection)
        end
      end
    end
  end

  # GET /collection_items/:id/edit
  def edit
    respond_to do |format|
      format.js do
        if current_user.can_update?(@collection_item)
          @collection = @collection_item.collection
          @references = ''
          @collection_item.refs.each do |ref|
            @references = @references + "\n" unless @references==''
            @references = @references + ref.full_reference
          end
          render :partial => 'collections/edit_collection_item', :locals => { :collection_item => @collection_item }
        else
          render :text => I18n.t(:collection_item_edit_by_javascript_not_authorized_error)
        end
      end
    end
  end

private

  def find_collection_item
    @collection_item = CollectionItem.find(params[:id], :include => [:collection])
    @selected_collection_items = [] # To avoid errors.  If you edit something, it becomes unchecked.  That's okay.
  end

  def create_collection_item(data)
    @collection_item = CollectionItem.new(data)
    @collection_item.collection ||= current_user.watch_collection unless current_user.blank?
    if @collection_item.collected_item_type == 'Collection' && @collection_item.collected_item_id == @collection_item.collection.id
      @notices << I18n.t(:item_not_added_to_itself_notice,
                               :collection_name => @collection_item.collection.name)
    elsif @collection_item.save
      CollectionActivityLog.create(:collection => @collection_item.collection, :user => current_user,
                                   :activity => Activity.collect, :collection_item => @collection_item)
      @collection_item.collection.updated_at = Time.now.to_s
      @collection_item.collection.save
      @notices << I18n.t(:item_added_to_collection_notice,
                               :collection_name => self.class.helpers.link_to(@collection_item.collection.name,
                                                   collection_path(@collection_item.collection)))
    else
      # TODO: Ideally examine validation error and provide more informative error message, e.g. item is
      # already in the collection etc
      @errors << I18n.t(:item_not_added_to_collection_error)
    end
  end

end
