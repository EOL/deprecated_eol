class CollectionItemsController < ApplicationController

  before_filter :allow_login_then_submit, :only => [:create]

  # POST /collection_items
  def create

    if session[:submitted_data]
      data = session[:submitted_data]
      session.delete(:submitted_data)
    end
    data ||= params

    @collection_item = CollectionItem.new(data[:collection_item])
    @collection_item.collection ||= current_user.watch_collection unless current_user.blank?

    return_to = data[:return_to]
    return_to ||= collection_path(@collection_item.collection) unless @collection_item.collection.blank?
    store_location(return_to)

    if @collection_item.object_type == 'Collection' && @collection_item.object_id == @collection_item.collection.id
      flash[:notice] = I18n.t(:item_not_added_is_watch_collection_notice, :collection_name => @collection_item.collection.name)
    elsif @collection_item.save
      CollectionActivityLog.create(:collection => self, :collection_item => collection_items.last,
                                   :user => current_user, :activity => Activity.collect)
      flash[:notice] = I18n.t(:item_added_to_collection_notice, :collection_name => @collection_item.collection.name)
    else
      flash[:error] = I18n.t(:item_not_added_to_collection_error)
    end
    redirect_back_or_default
  end

  # PUT /collection_items/1
  def update
    @collection_item = CollectionItem.find(params[:id])

    return_to = params[:return_to]
    return_to ||= collection_path(@collection_item.collection) unless @collection_item.blank?
    store_location(return_to)

    if @collection_item.update_attributes(params[:collection_item])
      flash[:notice] = I18n.t(:item_updated_in_collection_notice, :collection_name => @collection_item.collection.name)
    else
      flash[:error] = I18n.t(:item_not_updated_in_collection_error)
    end
    redirect_back_or_default
  end

  # DELETE /collection_items/1
  def destroy
    @collection_item = CollectionItem.find(params[:id])
    @collection_item.destroy

    respond_to do |format|
      format.html { redirect_to(collection_items_url) }
    end
  end

end
