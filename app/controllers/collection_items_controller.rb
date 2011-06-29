class CollectionItemsController < ApplicationController
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
    @collection_item = CollectionItem.new(params[:collection_item])

    respond_to do |format|
      if @collection_item.save
        format.html { redirect_to(@collection_item, :notice => 'CollectionItem was successfully created.') }
        format.xml  { render :xml => @collection_item, :status => :created, :location => @collection_item }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @collection_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /collection_items/1
  # PUT /collection_items/1.xml
  def update
    @collection_item = CollectionItem.find(params[:id])
    session[:return_to] ||= request.referer
    redirect_path = session[:return_to].nil? ? collection_items_url : session[:return_to]
    respond_to do |format|
      if @collection_item.update_attributes(params[:collection_item])
        format.html { redirect_to(redirect_path, :notice => 'Collection Item was successfully updated.') }
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
