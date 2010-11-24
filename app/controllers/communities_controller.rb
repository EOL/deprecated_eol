class CommunitiesController < ApplicationController

  def index
    @communities = Community.paginate(:page => params[:page]) 

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @communities }
    end
  end

  def show
    @community = Community.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @community }
    end
  end

  def new
    @page_title = "New EOL Community"[]
    @community = Community.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @community }
    end
  end

  def edit
    @community = Community.find(params[:id])
  end

  def create
    @community = Community.new(params[:community])

    respond_to do |format|
      if @community.save
        format.html { redirect_to(@community, :notice => 'Community was successfully created.'[:created_community]) }
        format.xml  { render :xml => @community, :status => :created, :location => @community }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @community.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @community = Community.find(params[:id])

    respond_to do |format|
      if @community.update_attributes(params[:community])
        format.html { redirect_to(@community, :notice => 'Community was successfully updated.'[:updated_community]) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @community.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @community = Community.find(params[:id])
    @community.destroy

    respond_to do |format|
      format.html { redirect_to(communities_url) }
      format.xml  { head :ok }
    end
  end

  def join
    @community = Community.find(params[:community_id])
    @community.add_member(current_user)
    respond_to do |format|
      format.html { redirect_to(@community, :notice => 'You have successfully joined this community.'[:you_joined_community]) }
    end
  end

  def leave
    @community = Community.find(params[:community_id])
    @community.remove_member(current_user)
    respond_to do |format|
      format.html { redirect_to(@community, :notice => 'You have successfully left this community.'[:you_left_community]) }
    end
  end

end
