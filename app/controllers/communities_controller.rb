class CommunitiesController < ApplicationController

  before_filter :load_community, :except => [:index, :new, :create]
  before_filter :must_be_logged_in, :except => [:index, :show]
  before_filter :restrict_edit_and_delete, :only => [:edit, :update, :delete]

  def index
    @communities = Community.paginate(:page => params[:page]) 

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @communities }
    end
  end

  def show
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
  end

  def create
    @community = Community.new(params[:community])
    respond_to do |format|
      if @community.save
        @community.initialize_as_created_by(current_user)
        format.html { redirect_to(@community, :notice => 'Community was successfully created.'[:created_community]) }
        format.xml  { render :xml => @community, :status => :created, :location => @community }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @community.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update

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
    @community.destroy
    respond_to do |format|
      format.html { redirect_to(communities_url) }
      format.xml  { head :ok }
    end
  end

  def join
    @community.add_member(current_user)
    respond_to do |format|
      format.html { redirect_to(@community, :notice => 'You have successfully joined this community.'[:you_joined_community]) }
    end
  end

  def leave
    @community.remove_member(current_user)
    respond_to do |format|
      format.html { redirect_to(@community, :notice => 'You have successfully left this community.'[:you_left_community]) }
    end
  end

  private

  def load_community
    @community = Community.find(params[:community_id] || params[:id])
  end

  def restrict_edit_and_delete
    member = current_user.member_of(@community)
    raise EOL::Exceptions::SecurityViolation unless member && member.can?(Privilege.edit_delete_community)
  end

  def must_be_logged_in
    raise EOL::Exceptions::MustBeLoggedIn unless logged_in?
  end

end
