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
    # We don't actually *destroy* collection items, so that we still have a log of what they were pointing to:
    if @collection_item.update_attributes(:collection_id => nil)
      CollectionActivityLog.create(:collection => @collection_item.collection, :collection_item => @collection_item,
                                   :user => current_user, :activity => Activity.remove)
      respond_to do |format|
        flash[:notice] = I18n.t(:item_removed_from_collection_notice, :collection_name => @collection_item.collection.name)
        format.html { redirect_to(@collection_item.collection) }
      end
    else
      flash[:error] = I18n.t(:item_not_updated_in_collection_error)
      redirect_back_or_default
    end
  end

end
