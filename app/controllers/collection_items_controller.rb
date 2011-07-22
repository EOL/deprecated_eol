class CollectionItemsController < ApplicationController

  before_filter :allow_login_then_submit, :only => [:create]
  before_filter :find_collection_item, :only => [:update, :edit]

  # POST /collection_items
  def create

    collection_item_data = params[:collection_item] unless params[:collection_item].blank?
    return_to = params[:return_to] unless params[:return_to].blank?
    if session[:submitted_data]
      collection_item_data ||= session[:submitted_data][:collection_item]
      return_to ||= session[:submitted_data][:return_to]
      session.delete(:submitted_data)
    end

    @collection_item = CollectionItem.new(collection_item_data)
    @collection_item.collection ||= current_user.watch_collection unless current_user.blank?

    return_to ||= collection_path(@collection_item.collection) unless @collection_item.collection.blank?
    store_location(return_to)

    if @collection_item.object_type == 'Collection' && @collection_item.object_id == @collection_item.collection.id
      flash[:notice] = I18n.t(:item_not_added_to_itself_notice, :collection_name => @collection_item.collection.name)
    elsif @collection_item.save
      flash[:notice] = I18n.t(:item_added_to_collection_notice, :collection_name => self.class.helpers.link_to(@collection_item.collection.name, collection_path(@collection_item.collection)))
    else
      # TODO: Ideally examine validation error and provide more informative error message, e.g. item is already in the collection etc
      flash[:error] = I18n.t(:item_not_added_to_collection_error)
    end
    redirect_back_or_default
  end

  # PUT /collection_items/1
  def update
    if @collection_item.update_attributes(params[:collection_item])
      respond_to do |format|
        format.js do
          render :partial => 'show', :layout => false,
            :locals => { :collection_item => @collection_item, :editable => true }
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

end
