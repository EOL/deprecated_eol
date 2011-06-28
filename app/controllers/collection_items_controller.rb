class CollectionItemsController < ApplicationController

  before_filter :allow_login_then_submit, :only => [:create]

  # GET /collection_items
  # GET /collection_items.xml
  def index
    @collection_items = CollectionItem.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @collection_items }
    end
  end

  # GET /collection_items/1
  # GET /collection_items/1.xml
  def show
    @collection_item = CollectionItem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @collection_item }
    end
  end

  # GET /collection_items/new
  # GET /collection_items/new.xml
  def new
    @collection_item = CollectionItem.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @collection_item }
    end
  end

  # GET /collection_items/1/edit
  def edit
    @collection_item = CollectionItem.find(params[:id])
  end

  # POST /collection_items
  # POST /collection_items.xml
  def create

    if session[:submitted_data]
      data = session[:submitted_data]
      session.delete(:submitted_data)
    end
    data ||= params

    store_location(data[:return_to])

    @collection_item = CollectionItem.new(:object_type => data[:object_type],
                                          :object_id => data[:object_id],
                                          :collection_id => data[:collection_id] )

    @collection_item.collection ||= current_user.watch_collection unless current_user.blank?

    respond_to do |format|
      if @collection_item.save
        flash[:notice] = I18n.t(:item_added_to_collection_name, :collection_name => @collection_item.collection.name)
        format.html { redirect_back_or_default }
        format.xml  { render :xml => @collection_item, :status => :created, :location => @collection_item }
      else
        flash[:error] = I18n.t(:item_not_added_to_collection_error)
        format.html { redirect_back_or_default }
        format.xml  { render :xml => @collection_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /collection_items/1
  # PUT /collection_items/1.xml
  def update
    @collection_item = CollectionItem.find(params[:id])

    respond_to do |format|
      if @collection_item.update_attributes(params[:collection_item])
        format.html { redirect_to(@collection_item, :notice => 'CollectionItem was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @collection_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /collection_items/1
  # DELETE /collection_items/1.xml
  def destroy
    @collection_item = CollectionItem.find(params[:id])
    @collection_item.destroy

    respond_to do |format|
      format.html { redirect_to(collection_items_url) }
      format.xml  { head :ok }
    end
  end
end
