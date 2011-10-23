class CollectionItemsController < ApplicationController

  before_filter :allow_login_then_submit, :only => [:create]
  before_filter :find_collection_item, :only => [:update, :edit]

  # POST /collection_items
  def create
    # TODO: this will remove the duplicate Global Site Message when collecting things. How can we better trap these cases?
    flash.now[:error] = nil
    @notices = []
    @errors = []
    # Sooo... we could get our data in a lot of different ways.
    if session[:submitted_data] # They are coming back from logging in, data is stored:
      store_location(session[:submitted_data][:return_to])
      session.delete(:submitted_data)
      create_collection_item(session[:submitted_data][:collection_item])
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
      format.html { redirect_to @collection_item.object }
      format.js do
        # this means we came from the collections summary on the overview page,
        # so render that entire summary box again
        if params[:render_overview_summary] && @collection_item.object.is_a?(TaxonConcept)
          if @errors.blank?
            @taxon_concept = TaxonConcept.find(@collection_item.object_id)
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

  # PUT /collection_items/1
  def update
    if @collection_item.update_attributes(params[:collection_item])
      respond_to do |format|
        format.js do
          # TODO - this won't work 'cause I'm using @collection_item to test whether to use a full form.  Fix:
          render :partial => 'edit', :locals => { :collection_item => @collection_item }
        end
        format.html do
          flash[:notice] = I18n.t(:item_updated_in_collection_notice, :collection_name => @collection_item.collection.name)
          redirect_to(@collection_item.collection)
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

  # TODO - html
  # TODO - permissions checking
  def edit
    # TODO - Abstract the find into a before filter and handle not found errors..
    respond_to do |format|
      format.html
      format.js do
        render :partial => 'edit', :locals => { :collection_item => @collection_item }
      end
    end
  end

private

  def find_collection_item
    @collection_item = CollectionItem.find(params[:id])
    @selected_collection_items = [] # To avoid errors.  If you edit something, it becomes unchecked.  That's okay.
  end

  def create_collection_item(data)
    @collection_item = CollectionItem.new(data)
    @collection_item.collection ||= current_user.watch_collection unless current_user.blank?
    if @collection_item.object_type == 'Collection' && @collection_item.object_id == @collection_item.collection.id
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
