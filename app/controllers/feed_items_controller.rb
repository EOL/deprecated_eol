class FeedItemsController < ApplicationController

  before_filter :find_feed, :only => [:index]

  def index
    if logged_in?
      # TODO - the thumbnail_url should be the user's thumbnail.
      @feed_item = FeedItem.new_for(:feed => @feed_source, :user => current_user)
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @feed_items }
    end
  end

  # GET /feed_items/1
  # GET /feed_items/1.xml
  def show
    @feed_item = FeedItem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @feed_item }
    end
  end

  # GET /feed_items/1/edit
  def edit
    @feed_item = FeedItem.find(params[:id])
  end

  # POST /feed_items
  # POST /feed_items.xml
  def create
    params[:feed_item][:user] = current_user
    @feed_item = FeedItem.new_for(params[:feed_item])

    respond_to do |format|
      if @feed_item.save
        format.html { redirect_to(@feed_item, :notice => 'FeedItem was successfully created.') }
        format.xml  { render :xml => @feed_item, :status => :created, :location => @feed_item }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @feed_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /feed_items/1
  # PUT /feed_items/1.xml
  def update
    @feed_item = FeedItem.find(params[:id])

    respond_to do |format|
      if @feed_item.update_attributes(params[:feed_item])
        format.html { redirect_to(@feed_item, :notice => 'FeedItem was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @feed_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /feed_items/1
  # DELETE /feed_items/1.xml
  def destroy
    @feed_item = FeedItem.find(params[:id])
    @feed_item.destroy

    respond_to do |format|
      format.html { redirect_to(feed_items_url) }
      format.xml  { head :ok }
    end
  end

private

  def find_feed
    type = params[:type]
    id   = params[:id]
    @feed_source = nil
    case type
    when "Community"
      @feed_source = Community.find(params[:id])
    when "DataObject"
      @feed_source = DataObject.find(params[:id])
    when "TaxonConcept"
      @feed_source = TaxonConcept.find(params[:id])
    when "User"
      @feed_source = User.find(params[:id])
    else
      raise EOL::Exceptions::UnknownFeedType
    end
    @feed = @feed_source.feed
  end

end
